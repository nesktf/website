+++
[BLOG_ENTRY]
title = "Backporting std::expected to C++20"
subtitle = "Getting dirty again with monads"
timestamp = 1766431501
slug = "1766431501-backporting-std::expected"
tags = ["programming", "c++"]
+++

## Why
After implementing my own version of `std::optional`
[in a previous post](/blog/1761687330-designing-an-optimized-nullable-type-in-c++20) I wanted to
try and do the same with `std::expected` since it works more or less the same in some ways.

I actually did implement a very rough version like a year ago, but it was very, very ugly to look
at and it only did the bare minimum. I delayed reimplementing it until I encounter a real problem
when using it, and that is exactly what happened some days ago when calling a copy constructor
suddenly prevented my 3D engine from compiling.

The why on using C++20 instead of updating to C++23 and using the standard library implementation
is because I'm too lazy to update my Debian 12 installation that only has GCC 12.2.0 (but not too
lazy to spend two days implementing this lmao) and because it's fun to reinvent the wheel.

## The idea
As I said before, the basic class structure for `std::expected` is more or less the same as
`std::optional`, you have a tagged union that can only hold one of two types. However, in this case
we cannot remove the flag for optimization purposes, so we have to live with an extra byte with
some padding.

```cpp
template<typename T, typename E>
class expected {
  union {
    T _value;
    E _error;
  };
  bool _has_value;
};
```

We also have a `void` partial specialization for the value type that works exactly the same as
`std::optional` for the error type, with the main difference being that `has_value` is false when
the class holds a value.

```cpp
template<typename E>
class expected<void, E> {
  union {
    char _dummy_value;
    E _error;
  };
  bool _has_value;
};
```

## Implementation
With only this base we can add all of the funcionality that the C++23 standard specifies. I try to
follow most of the implementation details on
[cppreference](https://en.cppreference.com/w/cpp/utility/expected.html) but I like having some
freedom to do things a little different if I feel the need to,

First let's talk about constructors. We need to have a way to know if we should construct either
`T` or `E`. For this, we define a wrapper class `unexpected<E>` for our error values and a tag
type `unexpect_t` for in place construction. We will use some `requires` constraints in some
cases to get more helpful compiler errors and to avoid partial specialization boilerplate.

```cpp
template<typename E>
class unexpected {
public:
  // We just forward an lvalue or rvalue reference
  template<typename G = E>
  unexpected(G&& error) :
    _error(std::forward<G>(error)) {}

public:
  // We define different accessors for lvalues and rvalues.
  // We will look more into this later.
  E& error() & { return _error; }
  const E& error() const& { return _error; }
  E&& error() && { return _error; }
  const E&& error() const&& { return _error; }

private:
  E _error;
};

using in_place_t = std::in_place_t;

struct unexpect_t {};
constexpr unexpect_t unexpect;

template<typename T, typename E>
class expected {
public:
  expected()
    requires(std::is_default_constructible_v<T>) :
    _value(), _has_value(true) {}

  expected(const T& obj)
    requires(std::is_copy_constructible_v<T>) :
    _value(obj), _has_value(true) {}

  expected(T&& obj)
    requires(std::is_move_constructible_v<T>) :
    _value(std::move(obj)), _has_value(true) {}

  template<typename... Args>
  expected(in_place_t, Args&&... args)
    requires(std::is_constructible_v<T, Args...>) :
    _value(std::forward<Args>(args)...), _has_value(true) {}

  expected(const unexpected<E>& unex)
    requires(std::is_copy_constructible_v<E>) :
    _error(unex.error()), _has_value(false) {}

  expected(unexpected<E>&& unex)
    requires(std::is_move_constructible_v<E>) :
    _error(std::move(unex).error()), _has_value(false) {}

  template<typename... Args>
  expected(unexpect_t, Args&&... args)
    requires(std::is_constructible_v<E, Args...>) :
    _error(std::forward<Args>(args)...), _has_value(false) {}

private:
  union {
    T _value;
    E _error;
  };
  bool _has_value;
};
```

The `void` specialization is more or less the same, but without defining the copy and move
constructors for `T`.

```cpp
template<typename E>
class expected<void, E> {
public:
  expected() noexcept :
    _value(), _has_value(true) {}

  template<typename... Args>
  expected(in_place_t, Args&&... args)
    requires(std::is_constructible_v<T, Args...>) :
    _value(std::forward<Args>(args)...), _has_value(true) {}

  expected(const unexpected<E>& unex)
    requires(std::is_copy_constructible_v<E>) :
    _error(unex.error()), _has_value(false) {}

  expected(unexpected<E>&& unex)
    requires(std::is_move_constructible_v<E>) :
    _error(std::move(unex).error()), _has_value(false) {}

  template<typename... Args>
  expected(unexpect_t, Args&&... args)
    requires(std::is_constructible_v<E, Args...>) :
    _error(std::forward<Args>(args)...), _has_value(false) {}

private:
  union {
    char _dummy_value;
    E _error;
  };
  bool _has_value;
};
```

I didn't declare the in place constructors `explicit` on purpose since I hate writing the overly
verbose explicit instanciation, and prefer to use the more elegant `{in_place, ...}`. It's bad
practice but I don't care. We can use these constructors like this

```cpp
expected<int, std::string> valid(20);
expected<int, std::string> also_valid(std::in_place, 20);
expected<void, std::string> also_also_valid; 
expected<int, std::string> error(unexpected(std::string{"An error"}));
expected<int, std::string> another_error(unexpect, "Also an error");

expected<int, std::string> some_func(bool fail) {
  if (fail) {
    return {unexpect, "Failed"};
  } else {
    return {in_place, 20};
  }
}
expected<int, std::string> some_func_explicit_ugly(bool fail) {
  if (fail) {
    return expected<int, std::string>{unexpect, "Failed"};
  } else {
    return expected<int, std::string>{in_place, 20};
  }
}
```

## Move semantics
From here on out, we will only define the general case. You can more or less imagine how to
implement the `void` specialization.

When defining move and copy operations I tried to do exactly as specified in the standard
for both correctness and a very particular optimization. Let's start with the destructor,
since it's the easiest part. We only define it if both `T` and `E` have a `non-trivial` destructor.

Usually, we say that a special member function (in this case, the destructor) for a type `T` is
trivial when it uses the compiler provided function (or the user explicitly defines it as default)
and when all of its members have the same trivial member function. Basically, you can think of a
completely trivial type as a plain C struct where nothing is defined. 

```cpp
template<typename T, typename E>
class expected {
private:
  static constexpr bool triv_destr_val = std::is_trivially_destructible_v<T>;
  static constexpr bool triv_destr_err = std::is_trivially_destructible_v<E>;
  static constexpr bool triv_destructible = triv_destr_val && triv_destr_err;

public:
  ~expected() noexcept requires(triv_destructible) = default

  ~expected() noexcept requires(!triv_destructible) {
    if constexpr (triv_destr_val && !triv_destr_err) {
      if (!_has_value) {
        std::destroy_at(std::addressof(_error));
      }
    } else if constexpr (!triv_destr_val && triv_destr_err) {
      if (_has_value) {
        std::destroy_at(std::addressof(_value));
      }
    } else {
      if (_has_value) {
        std::destroy_at(std::addressof(_value));
      } else {
        std::destroy_at(std::addressof(_error));
      }
    }
  }
};

// Example: two trivially destructible types
struct my_funny_type {
  int a;
  float b;
};
struct my_unfunny_type {
  char a;
  double b;

  ~my_unfunny_type() = default;
};
```

For copy and move constructors, we can use either the placement `new` operator or
`std::construct_at` (they are essentialy the same) to conditionally construct one of the union
members.

We can also take advantage of trivially copy and move constructible types for this optimization
that I mentioned earlier. When we copy or move a trivial type, the compiler usualy just calls
`memcpy` on the constructed object, so we want to take advantage of this as much as possible.

```cpp
template<typename T, typename E>
class expected {
private:
  static constexpr bool triv_copy =
    std::is_trivially_copy_constructible_v<T> && std::is_trivially_copy_constructible_v<E>;

public:
  expected(const expected& other) noexcept requires(triv_copy) = default;

  expected(const expected& other) :
    _has_value(other._has_value)
  {
    if (other._has_value) {
      new (std::addressof(_value)) T(other._value);
    } else {
      new (std::addressof(_error)) E(other._error);
    }
  }

  // Exactly the same for the move constructor
};
```

## Assignment and emplacing
Now we get to the hardest part, the assignment operators. These two plus the `emplace` member
function (that works basically the same as assigning a new value in place) can be a little bit
tricky to get right, since we have to deal with the cases when either `T` or `E` throw on copy
or move assignment.

We need to have special care here, since it's very easy to make a mistake and to never call a
constructor or call it twice. We use a helper function called `reinit_expected` that is defined
on the `operator=` page for `std::expected` from
[cppreference](https://en.cppreference.com/w/cpp/utility/expected/operator=.html) to swap the
two union values safely. I modified it a little bit to keep the `noexcept` flag and
specialized it for the case when we have an active `T` and an active `E`.

```cpp
template<typename T, typename E, typename... Args>
constexpr void reinit_valid_value(T& val, E& err, Args&&... args) 
noexcept(std::is_nothrow_constructible_v<T, Args...>)
{
  // Called when T is the currently active object
  if constexpr (std::is_nothrow_constructible_v<T, Args...>) {
    std::destroy_at(std::addressof(val));
    new (std::addressof(val)) T(std::forward<Args>(args)...);
  } else if constexpr (std::is_nothrow_move_constructible_v<T>) {
    T new_val(std::forward<Args>(args)...); // Might throw
    std::destroy_at(std::addressof(val));
    new (std::addressof(val)) T(std::move(new_val));
  } else {
    T old_val(std::move(val)); // Might throw
    std::destroy_at(std::addressof(val));
    try {
      new (std::addressof(val)) T(std::forward<Args>(args)...);
    } catch (...) {
      new (std::addressof(val)) T(std::move(old_val));
      throw;
    }
  }
}

template<typename T, typename E, typename... Args>
constexpr void reinit_invalid_value(T& val, E& err, Args&&... args)
noexcept(std::is_nothrow_constructible_v<T, Args...>)
{
  // Called when E is the currently active object
  if constexpr (std::is_nothrow_constructible_v<T, Args...>) {
    std::destroy_at(std::addressof(err));
    new (std::addressof(val)) T(std::forward<Args>(args)...);
  } else if constexpr (std::is_nothrow_move_constructible_v<T>) {
    T new_val(std::forward<Args>(args)...); // Might throw
    std::destroy_at(std::addressof(err));
    new (std::addressof(val)) T(std::move(new_val));
  } else {
    E old_err(std::move(err)); // Might or might not throw
    std::destroy_at(std::addressof(err));
    try {
      new (std::addressof(val)) T(std::forward<Args>(args)...);
    } catch (...) {
      new (std::addressof(err)) E(std::move(old_err));
      throw;
    }
  }
}
```
These two can seem a little daunting at first, but in reality they are very simple:

- If we can construct our object without throwing, we call the destructor for the active object and
just forward the arguments.
- If we can move from our object without throwing, we construct into a temporary value,
destroy the active object and move from the temporary.
- If everything throws we first try to move into a temporary and, if it doesn't throw, we forward
the arguments. If the forwarding constructor throws, we use the temporary value to return to a
valid state.

We can use two plus another extra case for errors (you can guess how it's implemented) to define
our `operator=` and `emplace` members

```cpp
template<typename T, typename E>
class expected {
public:
  constexpr expected& operator=(const expected& other) {
    if (std::addressof(other) == this) {
      return *this; // Avoid self assignment
    }

    if (_has_value) {
      if (other._has_value) {
        reinit_valid_value(_value, _error, other._value);
      } else {
        reinit_valid_error(_value, _error, other._error);
      }
    } else {
      if (other._has_value) {
        reinit_invalid_value(_value, _error, other._value);
      } else {
        reinit_invalid_error(_value, _error, other._error);
      }
    }

    return *this;
  }
  // Move assignment is the same, but we move from other._value and other._error

public:
  template<typename... Args>
  constexpr T& emplace(Args&&... args) {
    if (_has_value) {
      reinit_valid_value(_value, _error, std::forward<Args>(args)...);
    } else {
      reinit_invalid_value(_value, _error, std::forward<Args>(args)...);
      _has_value = true;
    }
    return _value;
  }
};
```

If you are wondering, just referencing both union members at the same time should be fine. It would
be UB only if we try to write to or read from the inactive member when the other one is active.

## Monadic operations
Now we get to the fun part. The standard defines four member functions that recieve callable
objects. Here is a brief explaination of each one:

- `and_then`: Recieves a callable with the signature `f(T) -> expected<U, E>` where `U` can be any
non reference type. It only invokes the callable when the error member is inactive.
- `or_else`: Recieves a callable with the signature `f(E) -> expected<T, G>` where `G` can be any
non void non reference type. It's the oposite of `and_then`, invokes the callable when the error is
the active memner
- `transform`: Recieves a callable with the signature `f(T) -> U` where `U` is a non reference
type. Invokes only when the error member is inactive.
- `transform_error`: Recieves a callable with signature `f(E) -> G` where `G` is a non void non
reference type. Invokes when the error member is active.

We can use these members to chain operations that get conditionally called based on the error
state of the object. `and_then` & `or_else` can be used for operations that can possibly
fail, and `transform` & `transform_error` can be used for operations that can be run without error.

```cpp
expected<int, std::domain_error> safe_divide(int a, int b) {
  if (b == 0) {
    return unexpected<std::domain_error>("Can't divide by zero");
  }
  return a / b;
}

int main() {
  const expected<float, std::string> result = safe_divide(2, 2)
        .transform([](int result) -> float { static_cast<float>(result); })
        .transform_error([](std::domain_error err) -> std::string { return err.what(); });
  std::cout << result.value() << "\n"; // Prints "1.0"

  const expected<int, std::string> result2 = safe_divide(10, 2)
    .and_then([](int result) -> expected<int, std::domain_error> {
      return safe_divide(result, 0); // Will fail
    })
    .or_else([](std::domain_error err) -> expected<int, std::string> {
        // Not called in this case, but shown for demonstration purposes
        try {
          return unexpected<std::string>(err.what());
        } catch (const std::bad_alloc&) {
          return 0; // Default value
        }
    });
  std::cout << result2.value() << "\n"; // Will throw
  std::cout << result2.error() << "\n"; // Prints "Can't divide by zero"
}
```

I will only show you my implementation for `and_then` for brevity, you can find the other three on
cppreference or on my final implementation. Keep in mind that you need to handle the `void`
specialization case separately, since we will use `decltype` on a return value and you can't use
it on a `void` return value.

```cpp
template<typename F, typename T>
struct expect_monadic_chain {
  using type = std::remove_cvref_t<std::invoke_result_t<F, T>>;
};

template<typename F>
struct expect_monadic_chain<F, void> {
  using type = std::remove_cvref_t<std::invoke_result_t<F>>;
};

template<typename T, typename E>
class expected {
public:
  template<typename F>
  constexpr auto and_then(F&& func) & {
    if constexpr (std::is_void_v<T>) {
      using U = impl::expect_monadic_chain_t<F, void>;
      static_assert(meta::expected_with_error<U, E>, "F needs to return an expected with error E");
      if (_has_value) {
        return std::invoke(std::forward<F>(func));
      } else {
        return U{unexpect, this->get_error()};
      }
    } else {
      // this->get() returns a reference to _value
      // this->get_error() does the same for _error
      using U = impl::expect_monadic_chain_t<F, decltype(this->get())>;
      static_assert(meta::expected_with_error<U, E>, "F needs to return an expected with error E");
      if (_has_value) {
        return std::invoke(std::forward<F>(func), this->get());
      } else {
        return U{unexpect, this->get_error()};
      }
    }
  }
  template<typename F>
  constexpr auto and_then(F&& func) const& { /* ... */ } // Same as above

  // Both same as above, but using decltype(std::move(this->get()))
  template<typename F>
  constexpr auto and_then(F&& func) && { /* ... */ }
  template<typename F>
  constexpr auto and_then(F&& func) const&& { /* ... */ }
};
```

If the error is active, we create a new expected value that wraps the same error value. If not we
just invoke the callable with our value and return the result, since the callable always returns
a new `expected` object.

You might have noticed that both here and on the `unexpected` class we define the same members
for both the lvalue and rvalue cases. This is necessary to be able to use the monadic operators on
rvalues like the example above, since we do not have deducing `this` on C++20 and we can't use
a template that conditionally moves the wrapped value.

## Conclusion
As is usually the case, getting my hands dirty and implementing this thing myself actually taught
me a lot more things about this shitty language and its quirks. I think it was worth it, since
it was a very fun experience.

I ended up using it quite a bit on my software projects, because I like how you can be very
explicit about your error handling (unlike exceptions).

Just like last time, you can find the full implementation on my
[standard library](https://github.com/nesktf/ntfstl/blob/master/include/ntfstl/expected.hpp).

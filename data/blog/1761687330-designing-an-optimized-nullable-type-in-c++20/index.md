+++
[BLOG_ENTRY]
title = "Designing an optimized nullable type in C++20"
subtitle = "Trying to design a space optimized std::optional"
timestamp = 1761687330
slug = "1761687330-designing-an-optimized-nullable-type-in-c++20"
tags = ["programming", "c++"]
+++
## A better nullable type (for some definition of better)
I recall reading or hearing somewhere that Rust's Option\<T\> can be optimized in some cases
to use the same size as its argument, so that would be size\_of::\<Option\<T\>\>() ==
size\_of::\<T\>().

I wanted to do something similar in C++, just because it looked like it would be fun (and to
keep adding more things to my own standard library)

## std::optional implementation
From what i have seen, the easiest way to represent a nullable type without messing around with
raw byte arrays is to just use an union with two members: Your T and a dummy object. However, this
approach would also need an additional flag to indicate if the union member is active or not.

```cpp
template<typename T>
class optional {
public:
  // More optional things...

private:
  union {
    T _obj;
    char _dummy;
  };
  bool _flag;
};
```

So when you are constructing the object and you to initialize your members, you just set
the flag to true. Keep in mind that, if you initialize the dummy instead of your object, it is
guaranteed that its lifetime will **not** start.

```cpp
template<typename T>
class optional {
public:
  optional() :
    _dummy{}, _flag{false} {}

  template<typename... Args>
  explicit optional(std::in_place_t, Args&&... args) :
    _obj{std::forward<Args>(args)...}, _flag{true} {}

public:
  ~optional() noexcept {
    if (has_value()) {
      _obj.~T();
    }
  }
  // Complete the rule of five...

public:
  bool has_value() const { return _flag; }
  // ...
};
```

However, as i just said this has some overhead from this flag (a *whole* extra byte, can you
believe it?). So i think that we can do better.

## Using traits
The only way (that i could think of) for us to eliminate this flag is to provide a "default" null
value for your T and check for it when we need to check for a null value.

The easiest way that i think would let us do this is creating a templated struct that we
can specialize to provide the null value. Other approaches exist like adding something like an
is\_null() method to your class, or adding a static member value to it, but i wanted to avoid
modifying the class directly. So we have something like the following:

```cpp
template<typename T>
struct optional_null {};
```

Then, we specialize it for our T. I added a special case for pointers as a general example too.

```cpp
// Your type
struct my_funny_type {
  my_funny_type(int value_ = 0) :
    value{value_} {}
  int value;
};

// Option 1
template<>
struct optional_null<my_funny_type> : public std::integral_constant<my_funny_type, my_funny_type{0}>;

// Option 2
template<>
struct optional_null<my_funny_type> {
  static constexpr my_funny_type value = my_funny_type{0};
};

// Partial specialization for pointers
template<typename T>
struct optional_null<T*> : public std::integral_constant<T*, nullptr> {};
```

You will also need to provide either an overload for operator==, operator!=, or provide a
static member function inside your traits struct to check if an object is null or not. I chose to
just add an overload to keep it simple for the pointer specialization.

```cpp
constexpr bool operator==(const my_funny_type& a, const my_funny_type& b) noexcept {
  return a.value == b.value;
}

constexpr bool operator!=(const my_funny_type& a, const my_funny_type& b) noexcept {
  return a.value != b.value;
}
```

We can then define some concepts to check if or `T` has a null value defined and an overload
for `operator==`.

```c++
template<typename T>
concept has_operator_equals = requires(const T a, const T b) {
  { a == b } -> std::convertible_to<bool>;
};

template<typename T>
concept has_operator_nequals = requires(const T a, const T b) {
  { a != b } -> std::convertible_to<bool>;
};

template<typename T>
concept valid_optional_type = !std::same_as<T, std::in_place_t> && !std::same_as<T, nullopt_t> &&
                              !std::is_void_v<T> && !std::is_reference_v<T>;

template<typename T>
concept optimized_optional_type = requires(T obj) {
  requires valid_optional_type<T>;
  requires std::same_as<T, std::remove_cv_t<decltype(optional_null<T>::value)>>;
  requires(meta::has_operator_nequals<T> || meta::has_operator_equals<T>);
};
```

We then define two versions for our optional class: One with the optimized storage and one
without

```cpp 
// Base case
template<typename T>
class optional_data {
public:
  optional_data() :
    _dummy{}, _flag{false} {}

  template<typename... Args>
  explicit optional_data(std::in_place_t, Args&&... args) :
    _obj{std::forward<Args>(args)...}, _flag{true} {}

public:
  ~optional_data() noexcept {
    if (has_value()) {
      _obj.~T();
    }
  }
  // Complete the rule of five...

public:
  bool has_value() const { return _flag; }
  // More optional things

private:
  union {
    T _obj;
    char _dummy;
  };
  bool _flag;
};

// Optimized case
template<typename T>
requires(optimized_optional_type<T>)
class optional_data {
public:
  optional_data() :
    _obj{optional_null<T>::value} {}

  template<typename... Args>
  explicit optional_data(std::in_place_t, Args&&... args) :
    _obj{std::forward<Args>(args)...} {}

  ~optional_data() noexcept = default // No need to define a destructor

public:
    bool has_value() const {
      if constexpr (has_operator_equals<T>) {
        return !(_obj == optional_null<T>::value);
      } else if constexpr (has_operator_nequals<T>) {
        return _obj != optional_null<T>::value;
      }
    }
    // Optional things...

private:
  T _obj;
};

// We then inherit from optional_data
template<valid_optional_type T>
class optional : public optional_data<T> {
  // Define your other optional methods, like emplace(), and_then(), transform(), ...
};
```

## Caveats
As you might have noticed, there are quite a few things to consider when taking this approach to
optimize the class.

First of all, your T **HAS** to ve copy constructible for it to be used in the optimized case,
otherwise you will encounter a very funny compilation error. You could add this as a requirement
in your optimized\_optional\_type concept if you want to.

Second, i first have said that i don't want to modify the original T class at all, but
then i came and said that you have to define an overload for operator== for this to work. This
might or might not be acceptable for you, but for me it is fine since you can add a non member
overload for it. The only case where this can become an issue is when you have no way to check
inside your class' public members for a null value, so you will either expose one in your class
definition, or define a member overload for operator==.

Finally, in some cases it might occur to you to add a specialization for an aliased type like the
following example

```cpp 
using my_funny_alias = uint32_t;

// Oh boy, i sure do hope nothing evil happens here
template<>
struct optional_null<my_funny_alias> : public std::integral_constant<my_funny_alias, 0>;
```

This, however, might bite you in the ass later on, because it actually specializes the null value
for **ALL** instances where you use uint32\_t (yes, C++ does not have type safe aliases), so this
is exactly as defining an optional\_null for uint32\_t

```cpp 
// Evil
template<>
struct optional_null<uint32_t> : public std::integral_constant<uint32_t, 0>;
```

If you still want to do add a specialization for an alias, consider making a simple type safe
wrapper (like in the main example and my\_funny\_type) or use a library to generate one for you.

## Conclusion
Doing this was a nice exercise. Its very fun to use C++20's concepts to avoid evil hacks like
SFINAE, and then go and use other evil hacks like the union lifetime thing.

You can find a complete implementation in [my standard library](https://github.com/nesktf/ntfstl/blob/master/include/ntfstl/optional.hpp).

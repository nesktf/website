+++
[BLOG_ENTRY]
title = "Using concept based runtime interfaces"
subtitle = "Inheritance? Who?"
timestamp = 1774538784
slug = "1774538784-using-concept-based-runtime-interfaces"
tags = ["programming", "cpp"]
+++

## Concepts as runtime interfaces
Recently while rewritting some parts of my rendering engine I came across a problem when abstracting
the windowing system. Basically, I wanted to be be able to establish some kind of interface
for an abstract window without having to use an inheritance tree.

At first i thought; we have concepts in C++20, I can just create a templated function and use a 
concept constraint, something like this:

```cpp
struct extent2d {
  uint32_t width, height;
};

template<typename T>
concept window_interface = requires(T win, const char* procname) {
  { win.gl_get_proc(procname) } -> std::same_as<void*>;
  { win.surface_extent(); } -> std::same_as<extent2d>;
};

template<window_interface Win>
void use_window(Win& win) {
  const auto [surface_width, surface_height] = win.surface_extent();
  const PFNGLGETSTRING glGetString = (PFNGLGETSTRING)win.gl_get_proc("glGetString");
  const char* version_string = (const char*)glGetString(GL_VERSION);
  // ...
}

struct glfw_window {
  void* gl_get_proc(const char* procname) { /* ... */ }
  extent2d surface_extent() { /* ... */ }
};
static_assert(window_interface<glfw_window>);

struct sdl_window {
  void* gl_get_proc(const char* procname) { /* ... */ }
  extent2d surface_extent() { /* ... */ }
};
static_assert(window_interface<sdl_window>);

int main() {
  glfw_window glfw;
  use_window(glfw);
  sdl_window sdl;
  use_window(sdl);
}
```

This actually worked for a bit, but it didn't last very long until I hit a major flaw.

When you are using concepts as interfaces, you are always using a **compile time constraint** over a 
templated function or class. This means that for it to be useful you **need** to have your function and
class definitions templated and available when you are compiling your current translation unit,
which in turn means that you have to bloat your headers with templated code and that you just cannot
have this type of interface on you library `.cpp` files. For example:

```cpp
// my_library.hpp
namespace my_library {

template<typename T>
concept window_interface = requires(T win, const char* procname) {
  { win.gl_get_proc(procname) } -> std::same_as<void*>;
  { win.surface_extent(); } -> std::same_as<extent2d>;
};

template<window_interface Win>
void use_window(Win& window);

} // namespace my_library

// my_library.cpp
#include "my_library.hpp"

namespace my_library {

template<window_interface Win>
void use_window(Win& win) {
  const auto [surface_width, surface_height] = win.surface_extent();
  const PFNGLGETSTRING glGetString = (PFNGLGETSTRING)win.gl_get_proc("glGetString");
  const char* version_string = (const char*)glGetString(GL_VERSION);
  // ...
}

} // namespace my_library

// my_application.cpp
#include "my_library.hpp"

struct glfw_window {
  void* gl_get_proc(const char* procname) { /* ... */ }
  extent2d surface_extent() { /* ... */ }
};
static_assert(my_library::window_interface<glfw_window>);

int main() {
  glfw_window glfw;
  my_library::use_window(glfw); // Error: We don't have the definition for use_window<glfw_window>
}
```

The only obvious way to solve this is to inherit from virtual class interface or to use the new modules
system from C++20 (which I still want to avoid until it is a bit more mature). I struggled a bit with
this until I remembered a very neat trick from a CPPcon video that solves this exact problem. 

## What's wrong with inheritance?
As I said, you can fix this easily by just inheriting from a pure virtual class with your interface,
like this:

```cpp
// my_library.hpp
namespace my_library {

struct window_interface {
  virtual ~window_interface() = default;
  virtual void* gl_get_proc(const char* procname) = 0;
  virtual extent2d surface_extent() = 0;
};

void use_window(window_interface& window);

} // namespace my_library

// my_application.cpp
#include my_library.hpp

struct glfw_window : public my_library::window_interface {
  void* gl_get_proc(const char* procname) override { /* ... */ }
  extent2d surface_extent() override { /* ... */ }
};

int main() {
  glfw_window glfw;
  my_library::use_window(glfw); // ok
}
```

Other than possible performance concerns from the virtual calls, which I am accepting as a tradeoff in
this case, I have some problems with using an inheritance hierarchy like this:

First, you still need to have the class definition for `window_interface` on every place where you
include `glfw_window`. This isn't as bad as having the template definition for every single case
where you are using the interface, but it can still be annoying when you want to avoid leaking
implementation details to other translation units or you just simply want to reduce compile times. You
cannot do something like this:

```cpp
// renderer.hpp
struct glfw_window : public my_library::window_interface {
  void* gl_get_proc(const char* procname) override;
  extent2d surface_extent() override;
};

// renderer.cpp
#include "my_library.hpp"
#include "renderer.hpp"

void* glfw_window::gl_get_proc(const char* procname) { /* ... */ }
extent2d glfw_window::surface_extent() { /* ... */ }

// main.cpp
#include "renderer.hpp"
// Error: "my_library.hpp" is not included in this translation unit, so glfw_window does not have any
// interface to inherit from

int main() {
  glfw_window win;
  // ...
}
```

There is also a caveat when you want to implement two different interfaces that have the same
function signatures. Let's say that you have two interfaces, `gl_window` and `vk_window`, both having
a `surface_extent` method. If your window inherits from both, which one are we defining?

```cpp
struct gl_window {
  virtual ~gl_window() = default;
  virtual void* gl_get_proc(const char* procname) = 0;
  virtual extent2d surface_extent() = 0;
};
struct vk_window {
  virtual ~vk_window() = default;
  virtual void* vk_get_proc(VkDevice device, const char* procname) = 0;
  virtual extent2d surface_extent() = 0;
};

struct glfw_window : public gl_window, public vk_window {
  void* gl_get_proc(const char* procname) override { /* ... */ }
  void* vk_get_proc(VkDevice device, const char* procname) override { /* ... */ }
  extent2d surface_extent() override {
    // Are we overriding gl_window::surface_extent or vk_window::surface_extent?
  }
};

```

Another problem is that using polymorphic classes implies some kind of ownership. When you are
defining a virtual class interface you usually also have to define a virtual destructor, even if you
are never going to have an owning reference to the derived class, otherwise the compiler starts
whining and asks you to add the virtual destructor (yes I know that you can disable this warning).

The final problem is that you depend on your compiler virtual dispatch system. This isn't that bad
really, but I prefer to have as much control as possible over this to squeeze more performance if I
need to.

## Stealing from Rust
I'm still a newbie when it comes to Rust, but one thing that I liked from it is that you can just
convert a compile time trait to a runtime one by just adding `dyn` to it, no inheritance needed.
I don't know anything about Rust internals, but I would guess that it just implicitly generates some
kind of vtable for any struct that has that trait.

So, we are going to do exactly the same thing: We will define a struct for our interface where
we are going to define a vtable on the fly. This vtable is just another struct with function pointers
in it that can be used on a void pointer. We will use what is commonly referred as "type erasure":

```cpp
// Constraint for creating the vtable
template<typename T>
concept window_constraint = requires(T win, const char* procname) {
  { win.gl_get_proc(procname) } -> std::same_as<void*>;
  { win.surface_extent(); } -> std::same_as<extent2d>;
};

class window_interface {
private:
  // 1. The vtable struct
  struct vtbl_t {
    void* (*gl_get_proc)(void* user, const char* procname);
    extent2d (*surface_extent)(void* user);
  };

  // 2. We generate the vtable here
  template<window_constraint Win>
  static constexpr vtbl_t vtbl_for {
    .gl_get_proc = +[](void* user, const char* procname) -> void* {
      return static_cast<Win*>(user)->gl_get_proc(procname);
    },
    .surface_extent = +[](void* user) -> extent2d {
      return static_cast<Win*>(user)->surface_extent();
    },
  };

public:
  template<typename Win>
  requires(window_constraint<std::remove_cvref_t<Win>>)
  window_interface(Win&& win) noexcept :
    _user(static_cast<void*>(std::addressof(win))),
	_vtbl(&vtbl_for<std::remove_cvref_t<Win>>) {}

public:
  // 3. The actual interface
  void* gl_get_proc(const char* procname) const {
    return _vtbl->gl_get_proc(_user, procname);
  }
  
  extent2d surface_extent() const {
    return _vtbl->surface_extent(_user);
  }

private:
  void* _user;
  const vtbl_t* _vtbl;
};
```

We do the following, in order:

- Define the vtable struct. Just a bunch of function pointers with the same method signature as the
virtual class interface but adding a void pointer.
- Create the vtable from a templated variable or templated factory function. We cast from the
void pointer to our concrete type. 
- Define the main interface that we will actually use.

That's it, as shrimple as that. If you are wondering, the `+[](){}` syntax on lambdas with the plus
sign at the front is used to make it explicit that we want a function pointer from the lambda instead 
of an object with captures.

Using this is as simple as intanciating a `window_interface` with
a reference to your concrete class object.

```cpp
// my_library.hpp
namespace my_library {

class window_interface {
  // ...
};

void use_window(window_interface win);

} // namespace my_library

// program.cpp
#include "my_library.hpp"

int main() {
  glfw_window win;
  my_library::use_window(win); // ok
}
```

## Owning version
If you instead want to use an owning reference, you need to add a destructor to your vtable (just like
the virtual class interface).

```cpp
class window_interface {
private:
  // 1. The vtable struct
  struct vtbl_t {
    void (*do_destroy)(void* user);
    void* (*gl_get_proc)(void* user, const char* procname);
    extent2d (*surface_extent)(void* user);
  };

  // 2. We generate the vtable here
  template<window_constraint Win>
  static constexpr vtbl_t vtbl_for {
    .do_destroy = +[](void* user) -> void {
      std::destroy_at(static_cast<Win*>(user));
	},
    .gl_get_proc = +[](void* user, const char* procname) -> void* {
      return static_cast<Win*>(user)->gl_get_proc(procname);
    },
    .surface_extent = +[](void* user) -> extent2d {
      return static_cast<Win*>(user)->surface_extent();
    },
  };

public:
  template<typename Win>
  requires(window_constraint<std::remove_cvref_t<Win>>)
  window_interface(Win&& win) noexcept :
    _user(std::malloc(sizeof(std::remove_cvref_t<Win>))),
	_vtbl(&vtbl_for<std::remove_cvref_t<Win>>) {
	// Important! We use malloc and free instead of new and delete
	std::construct_at(static_cast<std::remove_cvref_t<Win>*>(_user), std::forward<Win>(win));
  }
	
  // Special members
  ~window_interface() {
	if (_user) {
      _vtbl->do_destroy(_user);
	  std::free(_user);
	}
  }
  window_interface(window_interface&& other) noexcept :
    _user(other._user), _vtbl(other._vtbl) { other._user = nullptr; }
  window_interface(const window_interface&) = delete; // Non copyable
  
  window_interface& operator=(window_interface&& other) noexcept {
	if (_user) {
      _vtbl->do_destroy(_user);
	  std::free(_user);
	}
	
	_user = other._user;
	_vtbl = other._vtbl;
	
	other._user = nullptr;
	
	return *this;
  }
  window_interface& operator=(const window_interface&) = delete; // Non copyable

public:
  // 3. The actual interface
  void* gl_get_proc(const char* procname) const {
    return _vtbl->gl_get_proc(_user, procname);
  }
  
  extent2d surface_extent() const {
    return _vtbl->surface_extent(_user);
  }

private:
  void* _user;
  const vtbl_t* _vtbl;
};
```

In this case, we cannot use `new` and `delete` directly, since `delete` needs access to the 
window destructor and we do not have that if we type erase our pointer. To work around this, we use
`malloc` and `free` or `std::allocator` (you can easily replace that with a custom allocator if needed)
and we manually call the object's constructor and destructor.

You also have the option to instead use a small buffer to store your object on the interface itself
and avoid doing a heap allocation. You have full control over everything as I said previously.

## Single virtual call optimization
If you have the case where you only have a single virtual method in your interface you can remove
the vtable and replace it with a single function pointer. This is a bit more performant than the normal
version since we only have to make a single indirection (interface -> function) instead of two
(interface -> vtable -> function), but obviously you cannot use this optimization with
owning interfaces for non-trivially destructible types (since you will also need the destructor
function pointer).

Let's say for example that you want to implement your own `std::function_ref`. You only need to
wrap around an object that has `operator()` defined, so we only have a single virtual call:

```cpp
template<typename Signature>
class fn_ref; // We forward declare for the function signature trick

template<typename R, typename... Args>
class fn_ref<R(Args...)> {
private:
  // We generate the function pointer here
  template<typename T>
  requires(std::is_invocable_r_v<R, T, Args...>)
  static constexpr R call_for(void* user, Args... args) {
    return (*static_cast<T*>(user))(std::forward<Args>(args)...);
  }
  
public:
  template<typename T>
  requires(std::is_invocable_r_v<R, std::remove_cvref_t<T>, Args...>)
  fn_ref(T&& func) :
    _user(static_cast<void*>(std::addressof(func))),
	_call(&call_for<std::remove_cvref_t<T>>) {}

public:
  R operator()(Args... args) {
    // Then we just call our function
    return _call(_user, std::forward<Args>(args)...);
  }

private:
  void* _user;
  R (*_call)(void* user, Args... args);
};

void use_func(fn_view<void()> fn) {
  fn(); 
}

int main() {
  const auto example = []() -> void {
    printf("test\n");
  };
  use_func(example); // Prints "test"
}
```

Just like the previous example, you can use the same principle to make your own version of
`std::function` with ownership. I'm very lazy so I will not implement that here :p.

## Conclusion
The thing that I love about C++ is having the flexibility to do stupid things
like this; you have (almost) full access to your computer hardware and you can use that to do whatever
you want with it, even reimplementing constructs of the language itself
(in this case, polymorphic classes).

Of course, this comes with a price. We have to write a lot of boilerplate just to implement a simple
virtual interface and we have to use unsafe memory operations that you might or might not like
(using void pointers, managing lifetimes manually, ...). But for me, this is a reasonable price to pay.

Hopefully, with the release of the C++26 standard we can use reflection to reduce the boilerplate
needed to create this kind of interfaces. If i recall correctly, the CPPcon video that I got this idea
from was exactly about using reflection for that. I can't remember the exact video right now, but
if I find it again I will post it here.

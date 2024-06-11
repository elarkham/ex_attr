# ExAttr
![Hex.pm Version](https://img.shields.io/hexpm/v/ex_attr) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/ex_attr)

Simple utility library that performs native [extended attribute](https://man7.org/linux/man-pages/man7/xattr.7.html)
operations using rustler and the [`xattr`](https://github.com/Stebalien/xattr)
crate created by [Steven Allen](https://github.com/Stebalien).

In theory this should support every platform the [`xattr`](https://github.com/Stebalien/xattr) crate supports, which includes: Android, Linux, MacOS, FreeBSD, and NetBSD. However I've only tested this on Linux. 

## Rational
I was disappointed to see that there was no native interface within Elixir or Erlang's
standard libraries for managing extended attributes. While this can technically be worked
around by simply wrapping the `setfattr` and `getfattr` commands, I wasn't happy with the
performance of this approach.

Additionally, while there are similar libraries that handle xattr operations for Elixir,
I'm picky about how I handle serialization and was looking for something less opinionated
and "dumb" that I could easily wrap my application specific logic around.

Since I couldn't find anything that fit this criteria I figured I'd just do it myself, and so here we are!

## Installation

The package can be installed by adding `ex_attr` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_attr, "~> 2.0.0"}
  ]
end
```

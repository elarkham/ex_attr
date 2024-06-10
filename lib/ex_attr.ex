defmodule ExAttr do
  @moduledoc """
  Simple utility library that performs native [xattr](https://man7.org/linux/man-pages/man7/xattr.7.html)
  operations using rustler and the [`xattr`](https://docs.rs/xattr/latest/xattr/index.html)
  crate created by [Steven Allen](https://github.com/Stebalien)

  ### Rational
  I was disappointed to see that there was no native interface within Elixir or Erlang's
  standard libraries for managing extended attributes. While this can technically be worked
  around by simply wrapping the `setfattr` and `getfattr` commands, I wasn't happy with the
  performance of this approach.

  Additionally, while there are similar libraries that handle xattr operations for Elixir,
  I'm picky about how I handle serialization and was looking for something less opinionated
  and "dumb" that I could easily wrap my application specific logic around.

  Since I couldn't find anything that fit this criteria I figured I'd just do it myself, and so here we are!

  ### Namespacing Advise

  If you want to add some custom-application-specific xattrs to a file, it's generally a good idea to do this all
  under a common namespace specific to your application. Since POSIX extended attributes already has some built-in
  namespacing that differentiates between `trusted`, `system`, `user`, etc, it is highly likely you will need to make
  your namespace a child of the `user` namespace (ex: `"user.<my_namespace>"`) unless you are doing SELinux stuff.

  This is most easily abstracted away by simply wrapping the functions of this library to auto handle all that for you.
  Here is an example of what I mean:
  ```elixir
  defmodule MyApp.XAttr do
    @namespace "user.my_apps_namespace"

    def set(path, name, value) do
      name = "\#{@namespace}.\#{name}"
      ExAttr.set(path, name, value)
    end

    def get(path, name) do
      name = "\#{@namespace}.\#{name}"
      ExAttr.get(path, name)
    end

    def list(path) do
      case ExAttr.list(path) do
        {:ok, list} ->
          list
          |> Enum.filter(&match?("\#{@namespace}." <> _, &1))
          |> Enum.map(fn "\#{@namespace}." <> name -> name end)
          |> then(fn list ->
            {:ok, list}
          end)

        {:error, reason} ->
          {:error, reason}
      end
    end

    # And so on...
  end
  ```
  """
  alias ExAttr.Nif

  ##################
  #   Exceptions   #
  ##################

  defmodule Error do
    @moduledoc """
    An exception that is raised when a ExAttr operation fails.

    The following fields of this exception are public and can be accessed freely:

      * `:path` (`t:Path.t/0`) - the path of the file that caused the error
      * `:reason` (`t:String.t/0`) - the reason for the error

    """

    defexception [:reason, :path, action: ""]

    @impl true
    def message(%{action: action, reason: reason, path: path}) do
      "could not #{action} #{inspect(path)}: #{reason}"
    end
  end

  #############
  #   Types   #
  #############

  @type name()  :: String.t()
  @type value() :: String.t() | nil

  @type result(t) :: {:ok, t} | {:error, String.t()}
  @type result    :: :ok      | {:error, String.t()}

  #################
  #   Functions   #
  #################

  @doc """
  Forwards the result of the `xattr:SUPPORTED_PLATFORM` function from
  the `xattr` crate this library wraps.

  Returns true if platform is supported.
  """
  @spec supported_platform :: boolean()
  def supported_platform do
    ExAttr.Nif.supported_platform()
  end

  @doc """
  Get an extended attribute for the specified file.

  ## Examples

    iex> ExAttr.get("test.txt", "user.foo")
    {:ok, nil}
    iex> ExAttr.set("test.txt", "user.foo", "123")
    :ok
    iex> ExAttr.get("test.txt", "user.foo")
    {:ok, "123"}
  """
  @spec get(Path.t(), name()) :: result(value())
  def get(path, name) do
    case Nif.get_xattr(path, name) do
      {:error, reason} ->
        {:error, reason}

      nil ->
        {:ok, nil}

      value ->
        {:ok, to_string(value)}
    end
  end

  @doc """
  Get an extended attribute for the specified file, raises on error
  """
  @spec get!(Path.t(), name()) :: value()
  def get!(path, name) do
    case get(path, name) do
      {:error, reason} ->
        raise Error,
          action: "get xattr #{inspect name}",
          path: path,
          reason: reason

      {:ok, value} -> value
    end
  end

  @doc """
  Set an extended attribute on the specified file. Passing a `nil` value will remove the attribute.

  ## Examples

    iex> :ok = ExAttr.set("test.txt", "user.foo", "123")
    iex> {:ok, "123"} = ExAttr.get("test.txt", "user.foo")
    iex> :ok = ExAttr.set("test.txt", "user.foo", nil)
    iex> ExAttr.get("test.txt", "user.foo")
    {:ok, nil}
  """
  @spec set(Path.t(), name(), value()) :: result()
  def set(path, name, nil) do
    remove(path, name)
  end
  def set(path, name, value) do
    Nif.set_xattr(path, name, to_string(value))
  end

  @doc """
  Set an extended attribute on the specified file. Passing a `nil` value will remove the attribute, raises on error.
  """
  @spec set!(Path.t(), name(), value()) :: :ok
  def set!(path, name, value) do
    case set(path, name, value) do
      {:error, reason} ->
        raise Error,
          action: "set xattr #{inspect name} -> #{inspect value}",
          path: path,
          reason: reason

      :ok -> :ok
    end
  end

  @doc """
  Remove an extended attribute from the specified file.

  ## Examples

    iex> :ok = ExAttr.set("test.txt", "user.foo", "123")
    iex> {:ok, "123"} = ExAttr.get("test.txt", "user.foo")
    iex> :ok = ExAttr.remove("test.txt", "user.foo")
    iex> {:ok, nil} = ExAttr.get("test.txt", "user.foo")
    iex> ExAttr.remove("test.txt", "user.foo")
    {:error, "No data available (os error 61)"}
  """
  @spec remove(Path.t(), name()) :: result()
  def remove(path, name) do
    Nif.remove_xattr(path, name)
  end

  @doc """
  Remove an extended attribute from the specified file, raises on error.
  """
  @spec remove!(Path.t(), name()) :: :ok
  def remove!(path, name) do
    case Nif.remove_xattr(path, name) do
      {:error, reason} ->
        raise Error,
          action: "remove xattr #{inspect name}",
          path: path,
          reason: reason

      :ok -> :ok
    end
  end

  @doc """
  List extended attributes attached to the specified file.

  Note: this may not list all attributes. Speficially, it definitely won’t list any trusted attributes unless you are root and it may not list system attributes.

  ## Examples

    iex> :ok = ExAttr.set("test.txt", "user.foo", "bar")
    iex> :ok = ExAttr.set("test.txt", "user.bar", "foo")
    iex> :ok = ExAttr.set("test.txt", "user.test", "example")
    iex> ExAttr.list("test.txt")
    {:ok, ["user.test", "user.bar", "user.foo"]}
  """
  @spec list(Path.t()) :: result(list(name()))
  def list(path) do
    case Nif.list_xattr(path) do
      {:error, reason} -> {:error, reason}
      value -> {:ok, value}
    end
  end

  @doc """
  List extended attributes attached to the specified file, raises on error.

  Note: this may not list all attributes. Speficially, it definitely won’t list any trusted attributes unless you are root and it may not list system attributes.
  """
  @spec list!(Path.t()) :: list(name())
  def list!(path) do
    case Nif.list_xattr(path) do
      {:error, reason} ->
        raise Error,
          action: "list xattr",
          path: path,
          reason: reason

      value -> value
    end
  end

  @doc """
  Dumps map of extended attributes for the specified file.

  Note: this may not list all attributes. Speficially, it definitely won’t list any trusted attributes unless you are root and it may not list system attributes.

  ## Examples

    iex> :ok = ExAttr.set("test.txt", "user.foo", "bar")
    iex> :ok = ExAttr.set("test.txt", "user.bar", "foo")
    iex> :ok = ExAttr.set("test.txt", "user.test", "example")
    iex> ExAttr.dump("test.txt")
    {:ok, %{"user.bar" => "foo", "user.foo" => "bar", "user.test" => "example"}}
  """
  @spec dump(Path.t()) :: result(%{name() => value()})
  def dump(path) do
    case list(path) do
      {:ok, list} ->
        # If we can list the attribute names then we should be able to get their values
        {:ok, Map.new(list, fn name ->
          {name, get!(path, name)}
        end)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Dumps map of extended attributes for the specified file, raises on error.

  Note: this may not list all attributes. Speficially, it definitely won’t list any trusted attributes unless you are root and it may not list system attributes.
  """
  @spec dump!(Path.t()) :: %{name() => value()}
  def dump!(path) do
    case dump(path) do
      {:ok, map} ->
        {:ok, map}

      {:error, reason} ->
        raise Error,
          action: "dump xattr",
          path: path,
          reason: reason
    end
  end

end

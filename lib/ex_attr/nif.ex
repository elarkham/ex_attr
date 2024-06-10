defmodule ExAttr.Nif do
  @moduledoc """
  Wraps the [`xattr`](https://docs.rs/xattr/latest/xattr/index.html) crate using rustler
  """
  use Rustler,
    otp_app: :ex_attr,
    crate: "ex_attr_nif"

  def supported_platform,
    do: :erlang.nif_error(:nif_not_loaded)

  def get_xattr(_path, _name),
    do: :erlang.nif_error(:nif_not_loaded)

  def set_xattr(_path, _name, _value),
    do: :erlang.nif_error(:nif_not_loaded)

  def list_xattr(_path),
    do: :erlang.nif_error(:nif_not_loaded)

  def remove_xattr(_path, _name),
    do: :erlang.nif_error(:nif_not_loaded)

end

defprotocol Object do
  @type object_type :: :blob | :tree | :commit | :index
  @spec oid(t()) :: String.t()
  def oid(object)

  @spec type(t()) :: object_type()
  def type(object)

  @spec mode(t()) :: integer()
  def mode(object)
end

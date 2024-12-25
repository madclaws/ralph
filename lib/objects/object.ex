defprotocol Object do
  @type object_type :: :blob | :tree
  @spec oid(t()) :: String.t()
  def oid(object)

  @spec type(t()) :: object_type()
  def type(object)

  @spec data(t()) :: binary()
  def data(object)
end

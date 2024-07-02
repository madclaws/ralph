defmodule Ralph do
  @moduledoc """
  Documentation for `Ralph`.
  """

  require Logger

  def main(args) do
    args
    |> parse_options
    |> process_options
  end

  defp parse_options(args) do
    OptionParser.parse(args,
      switches: [],
      aliases: []
    )
  end

  def process_options(options) do
    Logger.info(inspect(options))
    display_help()
  end

  defp display_help() do
    IO.puts("""

    Usage:

    ralph

    """)

    System.halt(0)
  end
end

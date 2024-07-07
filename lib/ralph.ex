defmodule Ralph do
  @moduledoc """
  Documentation for `Ralph`.
  """
  alias Ralph.Commands

  require Logger

  def main(args) do
    args
    |> parse_options
    |> process_options
  end

  defp parse_options(args) do
    OptionParser.parse(args,
      switches: [init: :string],
      aliases: [i: :init]
    )
  end

  def process_options(options) do
    case options do
      {_, ["init", path], _} ->
        Commands.init(path)

      _ ->
        display_help()
    end
  end

  defp display_help() do
    IO.puts("""
    ralph #{Application.spec(:ralph, :vsn)}
    A teeny-tiny version control

    USAGE:
        ralph <SUBCOMMAND>
    """)

    System.halt(0)
  end
end

defmodule Ralph do
  @moduledoc """
  Documentation for `Ralph`.
  """
  alias Utils.Emojis
  require Logger

  def main(args) do
    args
    |> parse_options
    |> process_options
  end

  @spec parse_options(list()) ::
          {OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}
  defp parse_options(args) do
    OptionParser.parse(args,
      strict: []
      # aliases: [i: :init]
    )
  end

  @spec process_options({OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}) ::
          any()
  def process_options(options) do
    case options do
      {_, ["init", path], _} ->
        Commands.init(path)

      {_, ["commit"], _} ->
        Commands.commit()

      _ ->
        display_help()
    end
  end

  @spec display_help :: any()
  defp display_help() do
    IO.puts("""
    ralph #{Application.spec(:ralph, :vsn)} #{Emojis.emojis().christmas_tree}

    A teeny-tiny decentralized version control

    USAGE:
        ralph <SUBCOMMAND>
    """)

    System.halt(0)
  end

  def test_init(path) do
    Ralph.process_options({:a, ["init", path], :a})
  end
end

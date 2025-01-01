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
      strict: [message: :string],
      aliases: [m: :message]
    )
  end

  @spec process_options({OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}) ::
          any()
  def process_options(options) do
    case options do
      {_, ["init", path], _} ->
        Commands.init(path)
        System.halt(0)

      {[message: msg], ["commit"], _} ->
        Commands.commit(msg)
        System.halt(0)

      {[], ["add" | paths], []} ->
        Commands.add(paths)
        System.halt(0)

      {[], ["load"], []} ->
        Commands.load()

      {[], ["status"], []} ->
        Commands.status()
        System.halt(0)

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

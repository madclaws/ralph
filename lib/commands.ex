defmodule Commands do
  @moduledoc """
  Functions for CLI commands
  """
  alias Utils.Emojis
  alias Utils.Terminal

  @spec init(String.t()) :: any()
  def init(path) do
    abs_path = Path.expand(path)
    ralph_path = Path.join([abs_path, ".git"])

    ["objects", "refs"]
    |> Enum.each(fn folder ->
      try do
        File.mkdir_p!(Path.join([ralph_path, folder]))
      rescue
        err ->
          Terminal.puts(
            IO.ANSI.red(),
            "Sorry there's an error while creating files due to #{inspect(err)} #{Emojis.emojis().snowman}",
            :stderr
          )

          System.halt(1)
      end
    end)

    Terminal.puts(
      IO.ANSI.green(),
      "Initialized empty ralph repo at #{ralph_path} #{Emojis.emojis().clinking_glasses}"
    )

    System.halt(0)
  end
end

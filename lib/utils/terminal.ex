defmodule Utils.Terminal do
  @moduledoc false

  @spec puts(IO.ANSI.ansicode(), String.t(), atom()) :: :ok
  def puts(color, log, stream \\ nil) do
    IO.ANSI.reset()

    if stream do
      IO.puts(:stderr, IO.ANSI.format([color, log]))
    else
      IO.puts(IO.ANSI.format([color, log]))
    end

    IO.ANSI.clear()
  end
end

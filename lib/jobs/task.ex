defmodule Jobs.Task do
  @moduledoc """
  Module for task related functionality.
  """

  @doc """
  Executes the task in a shell.

  Returns {:ok} when task executed without errors, and {:error} otherwise
  """
  def execute(task) do
    case execute_command(Map.get(task, "command")) do
      {_, 0} -> {:ok}
      {_, _} -> {:error}
    end
  end

  @doc """
  Executes the command in a shell

  Returns {result, exit_status}
  """
  defp execute_command(command) do
    IO.puts("Executing command: #{command}")
    System.cmd("sh", ["-c", command])
  end
end

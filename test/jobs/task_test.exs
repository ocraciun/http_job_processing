defmodule Jobs.TaskTest do
  use ExUnit.Case, async: false

  @valid_task %{"name" => "task-1", "command" => "echo task-1"}
  @invalid_task %{"name" => "task-2", "command" => "echoooo"}

  test "it should return :error for invalid commands" do
    assert Jobs.Task.execute(@invalid_task) == {:error}
  end

  test "it should return :ok for valid commands" do
    assert Jobs.Task.execute(@valid_task) == {:ok}
  end
end

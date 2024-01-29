defmodule Jobs.JobTest do
  use ExUnit.Case, async: false
  doctest Jobs.Job

  @invalid_job %{
    "tasks" => [
      %{"name" => "task-1"},
      %{"name" => "task-2", "requires" => ["task-3"]}
    ]
  }

  @cycle_job %{
    "tasks" => [
      %{"name" => "task-1", "requires" => ["task-3"]},
      %{"name" => "task-2", "requires" => ["task-1"]},
      %{"name" => "task-3", "requires" => ["task-2"]}
    ]
  }

  @valid_job %{
    "tasks" => [
      %{"name" => "task-1", "command" => "echo task-1", "requires" => ["task-2"]},
      %{"name" => "task-2", "command" => "echo task-2", "requires" => ["task-3", "task-4"]},
      %{"name" => "task-3", "command" => "echo task-3", "requires" => ["task-4"]},
      %{"name" => "task-4", "command" => "echo task-4"}
    ]
  }

  describe "Job validation" do
    test "it detects missing required task from job" do
      result = Jobs.Job.execute(@invalid_job)

      assert result == {:error, :invalid}
    end

    test "it detects cycle in job" do
      result = Jobs.Job.execute(@cycle_job)

      assert result == {:error, :cycle}
    end

    test "it executes all commands in correct order" do
      result = Jobs.Job.execute(@valid_job)

      assert result ==
               {:ok,
                %{
                  "tasks" => [
                    %{"name" => "task-4", "command" => "echo task-4"},
                    %{"name" => "task-3", "command" => "echo task-3"},
                    %{"name" => "task-2", "command" => "echo task-2"},
                    %{"name" => "task-1", "command" => "echo task-1"}
                  ]
                }}
    end
  end
end

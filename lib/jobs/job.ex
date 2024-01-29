defmodule Jobs.Job do
  @moduledoc ~S"""
  Provides functions to execute a job and to get a bash representation of a job

  ## Examples

    iex> job = %{
    ...>  "tasks" => [
    ...>    %{"name" => "task-1", "command" => "echo task-1", "requires" => ["task-2"]},
    ...>    %{"name" => "task-2", "command" => "echo task-2"},
    ...>  ]
    ...> }
    iex> Jobs.Job.execute(job)
    {:ok, %{"tasks" => [
      %{"name" => "task-2", "command" => "echo task-2"},
      %{"name" => "task-1", "command" => "echo task-1"}
    ]}}

    iex> job = %{"tasks" => [
    ...>   %{"name" => "task-1", "command" => "echo task-1", "requires" => ["task-2"]},
    ...>   %{"name" => "task-2", "command" => "echo task-2"},
    ...> ]}
    iex> Jobs.Job.to_bash(job)
    {:ok, ~c"#!/usr/bin/env bash\necho task-2\necho task-1"}
  """

  @doc """
  Execute the job in a shell.

  Returns the job with tasks in execution order on success.
  Returns {:error, :cycle} when the job contains a cycle.
  Returns {:error, :invalid} when the job is missing a required task.
  Returns {:error, task_name} when the task command returned an error on execution.
  """
  def execute(job) do
    case can_execute?(job) do
      {:error, reason} ->
        {:error, reason}

      {:ok} ->
        job
        |> Map.get("tasks", [])
        |> sort_tasks()
        |> execute_tasks([])
        |> case do
          {:ok, tasks} ->
            {:ok, %{"tasks" => Enum.map(tasks, fn task -> Map.delete(task, "requires") end)}}

          {:error, task} ->
            {:error, task["name"]}
        end
    end
  end

  @doc """
  Converts the job to bash script representation

  Returns a string with the bash commands in correct execution order.
  Returns {:error, :cycle} when the job contains a cycle.
  Returns {:error, :invalid} when the job is missing a required task.
  """
  def to_bash(job) do
    case can_execute?(job) do
      {:error, reason} ->
        {:error, reason}

      {:ok} ->
        resp =
          job
          |> Map.get("tasks", [])
          |> sort_tasks()
          |> Enum.map(& &1["command"])
          |> List.insert_at(0, "#!/usr/bin/env bash")
          |> Enum.join("\n")
          |> String.to_charlist()

        {:ok, resp}
    end
  end

  @doc """
  Checks if a job can be executed successfully.

  Returns true if the job can be executed, or false otherwise.

  Verifies if all the required tasks are present in the job.
  Verifies if the job doesn't have a cycle.
  """
  defp can_execute?(job) do
    case has_valid_requires?(job) do
      true ->
        case has_cycle?(job) do
          true -> {:error, :cycle}
          false -> {:ok}
        end

      false ->
        {:error, :invalid}
    end
  end

  @doc """
  Verifies if all the required tasks are present in the job.

  Returns true if the job passes verification, and false otherwise.
  """
  defp has_valid_requires?(job) do
    tasks = Map.get(job, "tasks", [])

    Enum.all?(tasks, fn task ->
      Enum.all?(task["requires"] || [], fn name ->
        Enum.any?(tasks, &(&1["name"] == name))
      end)
    end)
  end

  @doc """
  Verifies if the job has a cycle.

  Returns true if a cycle is found, and false otherwise.
  """
  defp has_cycle?(job) do
    job
    |> Map.get("tasks", [])
    |> Enum.reduce(%{}, fn task, acc ->
      name = Map.get(task, "name")
      requires = Map.get(task, "requires", [])
      Map.put(acc, name, requires)
    end)
    |> dfs()
  end

  @doc """
  Perform a depth first search for the tasks in order to detect cycles.

  Returns true if a cycle is found
  """
  defp dfs(tasks), do: dfs(Map.keys(tasks), tasks, %{})
  defp dfs([], _tasks, _visited), do: false

  defp dfs([name | rest], tasks, visited) do
    case dfs_visit(name, tasks, visited) do
      true -> true
      false -> dfs(rest, tasks, visited)
    end
  end

  @doc """
  Visit a given task and all its required tasks.

  Returns true if any task was already marked as visited
  """
  defp dfs_visit(name, tasks, visited) do
    case Map.get(visited, name, :not_visited) do
      :visited ->
        true

      :not_visited ->
        visited = Map.put(visited, name, :visited)
        requires = Map.get(tasks, name, [])

        Enum.any?(requires, fn require ->
          dfs_visit(require, tasks, visited)
        end)
    end
  end

  @doc """
  Sorts the tasks based on their required list.

  Returns a list of tasks in the correct order of execution
  """
  defp sort_tasks(tasks) do
    Enum.sort_by(tasks, &task_priority(&1, tasks))
  end

  @doc """
  Get task priority.
  Should be used only when there are no circular dependencies.

  Returns a number representing the task priority
  """
  defp task_priority(task, tasks), do: task_priority(task, task["requires"] || [], tasks)
  defp task_priority(_, [], _), do: 0

  defp task_priority(_, requires, tasks) do
    requires_priorities =
      Enum.map(requires, fn name ->
        task = Enum.find(tasks, &(&1["name"] == name))
        task_priority(task, task["requires"] || [], tasks)
      end)

    1 + Enum.max(requires_priorities)
  end

  @doc """
  Executes the tasks in the given order.

  Returns {:ok, tasks} on success and {:error, task} when task failed to execute
  """
  defp execute_tasks([], executed), do: {:ok, executed}

  defp execute_tasks([task | rest], executed) do
    case Jobs.Task.execute(task) do
      {:ok} -> execute_tasks(rest, executed ++ [task])
      {:error} -> {:error, task}
    end
  end
end

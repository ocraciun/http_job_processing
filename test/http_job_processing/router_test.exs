defmodule HttpJobProcessing.RouterTest do
  use ExUnit.Case, async: false
  use Plug.Test

  @opts HttpJobProcessing.Router.init([])
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
      %{"name" => "task-1", "command" => "echo task-1", "requires" => ["task-3"]},
      %{"name" => "task-2", "command" => "echo task-2"},
      %{"name" => "task-3", "command" => "echo task-3", "requires" => ["task-2"]}
    ]
  }

  describe "/api/execute endpoint" do
    test "it returns correct response for a valid job" do
      conn = conn(:post, "/api/execute", @valid_job)
      conn = HttpJobProcessing.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == Jason.encode!(%{"tasks" => [%{"name" => "task-2", "command" => "echo task-2"}, %{"name" => "task-3", "command" => "echo task-3"}, %{"name" => "task-1", "command" => "echo task-1"}]})
    end

    test "it returns correct error for invalid job" do
      conn = conn(:post, "/api/execute", @invalid_job)
      conn = HttpJobProcessing.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == "Missing required task"
    end

    test "it returns correct error for a job with cycle" do
      conn = conn(:post, "/api/execute", @cycle_job)
      conn = HttpJobProcessing.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == "Job contains a cycle"
    end

    test "it returns correct error when a task has invalid command" do
      conn = conn(:post, "/api/execute", %{"tasks" => [%{"name" => "task-1", "command" => "invalid_command"}]})
      conn = HttpJobProcessing.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == "Task task-1 has failed"
    end
  end

  describe "/api/bash endpoint" do
    test "it returns correct response for a valid job" do
      conn = conn(:post, "/api/bash", @valid_job)
      conn = HttpJobProcessing.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "#!/usr/bin/env bash\necho task-2\necho task-3\necho task-1"
    end

    test "it returns correct error for invalid job" do
      conn = conn(:post, "/api/bash", @invalid_job)
      conn = HttpJobProcessing.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == "Missing required task"
    end

    test "it returns correct error for a job with cycle" do
      conn = conn(:post, "/api/bash", @cycle_job)
      conn = HttpJobProcessing.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == "Job contains a cycle"
    end
  end

  test "it returns 404 when no route matches" do
    conn = conn(:post, "/not_found")
    conn = HttpJobProcessing.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "Not found"
  end
end

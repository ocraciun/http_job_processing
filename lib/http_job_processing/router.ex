defmodule HttpJobProcessing.Router do
  @moduledoc """
  This is the router module.
  Here you can find all the routes and plugs.
  """
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  @doc """
  /api/execute endpoint.

  Executes the job
  The body should have a job in json format.
  Returns the job with tasks in execution order
  """
  post "/api/execute" do
    Jobs.Job.execute(conn.body_params) |> handle_response(conn)
  end

  @doc """
  /api/bash endpoint.

  The body should have a job in json format.
  Returns a bash script representation of the job
  """
  post "/api/bash" do
    Jobs.Job.to_bash(conn.body_params) |> handle_response(conn)
  end

  @doc """
  Handles all calls to unexisting endpoints
  """
  match _ do
    {:error, :not_found} |> handle_response(conn)
  end

  @doc """
  Formats the response and sends it back to the client
  """
  defp handle_response(response, conn) do
    %{code: code, message: message} =
      case response do
        {:ok, message} when is_map(message) -> %{code: 200, message: Jason.encode!(message)}
        {:ok, message} -> %{code: 200, message: message}
        {:error, :cycle} -> %{code: 400, message: "Job contains a cycle"}
        {:error, :invalid} -> %{code: 400, message: "Missing required task"}
        {:error, :not_found} -> %{code: 404, message: "Not found"}
        {:error, name} -> %{code: 400, message: "Task #{name} has failed"}
      end

    conn |> send_resp(code, message)
  end
end

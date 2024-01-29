defmodule HttpJobProcessing.Application do

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: HttpJobProcessing.Router,
        options: [port: 4001]
      )
    ]

    opts = [strategy: :one_for_one, name: HttpJobProcessing.Supervisor]

    Supervisor.start_link(children, opts)
  end
end

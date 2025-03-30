defmodule WebPush.Config do
  use Agent

  def start_link(_) do
    seed =
      Application.get_env(:web_push, :vapid_secret)
      |> Base.decode64!()

    {pub, sec} = :crypto.generate_key(:ecdh, :prime256v1, seed)

    config = %{
      json_library: Application.get_env(:web_push, :json_library),
      sub: Application.get_env(:web_push, :sub),
      public_key: pub,
      secret_key: sec
    }

    Agent.start_link(fn -> config end, name: __MODULE__)
  end

  def json_library() do
    Agent.get(__MODULE__, fn c -> c.json_library end)
  end

  def public_key() do
    Agent.get(__MODULE__, fn c -> c.public_key end)
  end

  def secret_key() do
    Agent.get(__MODULE__, fn c -> c.secret_key end)
  end

  def sub() do
    Agent.get(__MODULE__, fn c -> c.sub end)
  end
end

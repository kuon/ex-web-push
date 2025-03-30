defmodule Mix.Tasks.Vapid do
  @moduledoc "Generate a new VAPID key pair"

  use Mix.Task
  @impl Mix.Task

  def run(_args) do
    {pub, priv} = :crypto.generate_key(:ecdh, :prime256v1)
    pub = pub |> Base.encode64()
    priv = priv |> Base.encode64()

    IO.puts("VAPID public key: #{pub}")
    IO.puts("VAPID secret key: #{priv}")
    IO.puts("Add `export VAPID_SECRET=<priv>` to your environment")
    IO.puts("")
    IO.puts("export VAPID_SECRET=\"#{priv}\"")
    IO.puts("")
    IO.puts("Public key is not required in environment variable")
  end
end

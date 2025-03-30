defmodule WebPush do
  use Application

  alias WebPush.Config

  @doc false
  def start(_, _) do
    Supervisor.start_link(
      [
        WebPush.Config
      ],
      strategy: :one_for_one,
      name: __MODULE__.Supervisor
    )
  end

  def send(subscription, message) do
    message = message |> Config.json_library().encode!()
    {:ok, auth} = WebPush.Vapid.auth_header(subscription)

    {:ok, encrypted_data} =
      WebPush.Encrypt.encrypt(message, subscription)

    Req.post(subscription.endpoint,
      body: encrypted_data,
      headers: %{
        "Content-Type" => "application/octet-stream",
        "Authorization" => auth,
        "Content-Encoding" => "aes128gcm",
        "TTL" => 60
      }
    )
  end
end

defmodule WebPush.Vapid do
  import WebPush.Config, only: [json_library: 0, public_key: 0,
    secret_key: 0, sub: 0]

  def auth_header(subscription) do
    aud =
      URI.parse(subscription.endpoint)
      |> Map.put(:path, nil)
      |> URI.to_string()

    jwt_header =
      %{typ: "JWT", alg: "ES256"}
      |> json_library().encode!()
      |> Base.url_encode64(padding: false)

    jwt_body =
      %{
        sub: sub(),
        aud: aud,
        exp: :os.system_time(:seconds) + 12 * 3600
      }
      |> json_library().encode!()
      |> Base.url_encode64(padding: false)

    jwt_to_sign = jwt_header <> "." <> jwt_body

    jwt_sig =
      sign(jwt_to_sign)
      |> Base.url_encode64(padding: false)

    jwt = jwt_to_sign <> "." <> jwt_sig

    pk = public_key()
    |> Base.url_encode64(padding: false)

    {:ok, "vapid t=" <> jwt <> ",k=" <> pk}
  end

  def sign(iodata) do
    :crypto.sign(:ecdsa, :sha256, iodata, [secret_key(), :prime256v1])
    |> decode_der()
  end

  defp decode_der(<<0x30, len, rest::binary>>) when len == byte_size(rest) do
    {r, rest} = decode_der_int(rest)
    {s, _rest} = decode_der_int(rest)

    r <> s
  end

  defp decode_der(_) do
    {:error, :invalid_data}
  end

  defp decode_der_int(<<0x2, len, n::binary-size(len), rest::binary>>) do
    out_len = 32

    has_top_bit = len == out_len + 1

    n =
      if has_top_bit do
        <<0, n::binary-size(out_len)>> = n
        n
      else
        n
      end

    {n, rest}
  end
end

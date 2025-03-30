defmodule WebPush.Encrypt do
  def encrypt(message, subscription, padding_length \\ 10)

  def encrypt(message, subscription, padding_length)
      when byte_size(message) < 4000 do
    payload = message <> <<0x2>> <> :binary.copy(<<0>>, padding_length)

    client_public_key = subscription.p256dh
    client_auth_token = subscription.auth

    salt = :crypto.strong_rand_bytes(16)

    {server_public_key, server_secret_key} =
      :crypto.generate_key(:ecdh, :prime256v1)

    shared_secret =
      :crypto.compute_key(
        :ecdh,
        client_public_key,
        server_secret_key,
        :prime256v1
      )

    info = "WebPush: info" <> <<0>> <> client_public_key <> server_public_key
    content_encryption_key_info = "Content-Encoding: aes128gcm" <> <<0>>
    nonce_info = "Content-Encoding: nonce" <> <<0>>

    prk = hkdf(client_auth_token, shared_secret, info, 32)
    content_encryption_key = hkdf(salt, prk, content_encryption_key_info, 16)
    nonce = hkdf(salt, prk, nonce_info, 12)

    ciphertext = encrypt_payload(payload, content_encryption_key, nonce)

    header =
      salt <>
        <<byte_size(ciphertext)::unsigned-big-integer-size(32)>> <>
        <<byte_size(server_public_key)::unsigned-big-integer-size(8)>> <>
        server_public_key

    {:ok, header <> ciphertext}
  end

  def encrypt(_payload, _subscription, _padding_length) do
    {:error, :invalid_argument}
  end

  defp hkdf(salt, ikm, info, length) do
    prk =
      :crypto.mac_init(:hmac, :sha256, salt)
      |> :crypto.mac_update(ikm)
      |> :crypto.mac_final()

    :crypto.mac_init(:hmac, :sha256, prk)
    |> :crypto.mac_update(info)
    |> :crypto.mac_update(<<1>>)
    |> :crypto.mac_final()
    |> :binary.part(0, length)
  end

  defp encrypt_payload(plaintext, content_encryption_key, nonce) do
    {cipher_text, cipher_tag} =
      :crypto.crypto_one_time_aead(
        :aes_128_gcm,
        content_encryption_key,
        nonce,
        plaintext,
        "",
        true
      )

    cipher_text <> cipher_tag
  end
end

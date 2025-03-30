## WebPush helper for elixir

This library is intended to be used for sending web push notification in your
app.

It only handles the cryptography and posting of notification. You need to manage
the rest.

### Configuration and usage

You need to configure your elixir project, in `config.exs`

```elixir

# generate VAPID_SECRET with
# mix vapid


config :web_push,
    json_library: Jason,
    vapid_secret: System.get_env("VAPID_SECRET"),
    sub: "mailto:admin@example.com" # can also be an HTTPS url
    # sub ref: https://datatracker.ietf.org/doc/html/rfc8292#section-2.1

```

Then from your javascript side, you need to register your service worker and
create a subscription.

```js

const public_key = <here you need to fetch public key from server, which
                    is WebPush.Vapid.public_key() in elixir>

const sw_reg = await navigator.serviceWorker.register("/sw.js")

await navigator.serviceWorker.ready

let sub = await sw_reg.pushManager.getSubscription()
if (!sub) {
    const opts = {
        userVisibleOnly: true,
        applicationServerKey: public_key, // Ass Uint8Array
    }
    try {
        sub = await sw_reg.pushManager.subscribe(opts)
    } catch (e) {
        return null
    }
}

// Now that you have a registration, you need to pass it to the server

const params_to_send_to_server = {
  endpoint: sub.endpoint,
  auth: sub.getKey("auth"),
  p256dh: sub.getKey("p256dh"),
}

// Server side, this is a %Subscription{}
```


Then, with your subscription, you can do:

```elixir
WebPush.send(subscription, msg) # msg will be encoded in json, so it must be
                                # something the json_library can encode
```

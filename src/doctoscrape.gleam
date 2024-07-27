import gleam/erlang/process
import mist
import web/router
import web/web
import wisp

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)
  let ctx = web.Context(static_directory: static_directory())
  let handler = router.handle_request(_, ctx)

  // Start the server
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("doctoscrape")
  priv_directory <> "/static"
}

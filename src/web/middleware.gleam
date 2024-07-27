import cors_builder
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/result
import gleam/string
import lustre/element/html.{div, text}
import web/layouts
import web/web.{type Context}
import wisp.{type Request, type Response}

pub fn middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- cors_builder.wisp_middleware(req, cors())
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)
  use req <- require_hx_request(req, under: "/hx")

  handle_request(req)
}

fn cors() {
  cors_builder.new()
  |> cors_builder.allow_origin("http://localhost:1234")
  |> cors_builder.allow_method(Get)
  |> cors_builder.allow_method(Post)
}

fn require_hx_request(
  req: Request,
  under prefix: String,
  next handle_request: fn(Request) -> Response,
) -> Response {
  let path = remove_preceeding_slashes(req.path)
  let prefix = remove_preceeding_slashes(prefix)

  let is_hx_header =
    request.get_header(req, "HX-Request")
    |> result.unwrap("false")
    |> string_to_bool
    |> result.unwrap(False)

  let is_hx_path = string.starts_with(path, prefix)

  case is_hx_header, is_hx_path {
    False, False -> handle_request(req)
    True, True -> handle_request(req)
    _, _ -> is_not_htmx_request_view(req)
  }
}

fn string_to_bool(str: String) -> Result(Bool, Nil) {
  case string.lowercase(str) {
    "true" -> Ok(True)
    "false" -> Ok(False)
    _ -> Error(Nil)
  }
}

fn remove_preceeding_slashes(string: String) -> String {
  case string {
    "/" <> rest -> remove_preceeding_slashes(rest)
    _ -> string
  }
}

fn is_not_htmx_request_view(req: Request) -> Response {
  layouts.partial_layout(req, div([], [text("htmx error")]), 400)
}

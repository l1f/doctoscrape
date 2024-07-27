import cors_builder
import gleam/bool
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/io
import gleam/result
import gleam/string
import lustre/attribute.{class, href, rel, type_, value}
import lustre/element.{type Element}
import lustre/element/html.{
  body, div, form, h1, head, html, input, link, main as html_main, text, title,
}
import mist
import wisp.{type Request, type Response}

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)
  let ctx = Context(static_directory: static_directory())
  let handler = handle_request(_, ctx)

  // Start the server
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

// Router  ----

type Context {
  Context(static_directory: String)
}

fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> home(req)
    _ -> not_found_view(req)
  }
}

fn require_hx_request(
  req: Request,
  under prefix: String,
  next handle_request: fn(Request) -> Response,
) -> Response {
  let path = remove_preceeding_slashes(req.path)
  let prefix = remove_preceeding_slashes(prefix)

  // TODO: Parse to bool
  let is_hx_header =
    result.unwrap(request.get_header(req, "HX-Request"), "false")
  let is_hx_path = string.starts_with(path, prefix)

  case is_hx_header, is_hx_path {
    "false", False -> handle_request(req)
    "true", True -> handle_request(req)
    _, _ -> is_not_htmx_request_view(req)
  }
}

fn remove_preceeding_slashes(string: String) -> String {
  case string {
    "/" <> rest -> remove_preceeding_slashes(rest)
    _ -> string
  }
}

fn cors() {
  cors_builder.new()
  |> cors_builder.allow_origin("http://localhost:1234")
  |> cors_builder.allow_method(Get)
  |> cors_builder.allow_method(Post)
}

fn middleware(
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

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("doctoscrape")
  priv_directory <> "/static"
}

// Views ----

fn home(req: Request) -> Response {
  case req.method {
    Get -> home_view(req)
    _ -> wisp.method_not_allowed([Get])
  }
}

fn home_view(req: Request) -> Response {
  base_layout(
    req,
    div([class("home")], [
      form([class("search")], [
        div([class("search-title-wrapper")], [
          div([class("search-title")], [h1([], [text("Doctoscrape")])]),
          text(
            "Schedule doctolib lookups to get notification about rare appointment slots",
          ),
        ]),
        div([class("search-area")], [
          input([class("search-input")]),
          input([class("search-submit"), type_("submit"), value("Submit")]),
        ]),
        div([], []),
      ]),
    ]),
    200,
  )
}

fn not_found_view(req: Request) -> Response {
  base_layout(req, h1([], [text("Page Not Found")]), 404)
}

fn is_not_htmx_request_view(req: Request) -> Response {
  partial_layout(req, div([], [text("htmx error")]), 400)
}

// layouts ----

fn base_layout(_req: Request, children: Element(a), status: Int) -> Response {
  let html =
    html([], [
      head([], [
        title([], "Doctoscrape"),
        link([rel("stylesheet"), href("/static/style.css")]),
      ]),
      body([], [html_main([], [children])]),
    ])

  let response = element.to_document_string_builder(html)
  wisp.html_response(response, status)
}

fn partial_layout(_req: Request, children: Element(a), status: Int) -> Response {
  let response = element.to_document_string_builder(children)
  wisp.html_response(response, status)
}

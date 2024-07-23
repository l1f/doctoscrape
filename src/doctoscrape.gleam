import cors_builder
import gleam/erlang/process
import gleam/http.{Get, Post}
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
            "Doctoscrape is a tool schedule doctolib lookups to get notification about rare appointment slots",
          ),
        ]),
        div([class("search-area")], [
          input([class("search-input")]),
          input([class("search-submit"), type_("submit"), value("Submit")]),
        ]),
      ]),
    ]),
    200,
  )
}

fn not_found_view(req: Request) -> Response {
  base_layout(req, h1([], [text("Page Not Found")]), 404)
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

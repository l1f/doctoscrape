import gleam/http.{Get}
import lustre/attribute.{class, type_, value}
import lustre/element/html.{div, form, h1, input, text}
import web/layouts
import wisp.{type Request, type Response}

pub fn home(req: Request) -> Response {
  case req.method {
    Get -> home_view(req)
    _ -> wisp.method_not_allowed([Get])
  }
}

fn home_view(req: Request) -> Response {
  layouts.base_layout(
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

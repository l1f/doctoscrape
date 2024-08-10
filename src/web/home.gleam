import gleam/http.{Get}
import lustre/attribute.{class, id, name, type_}
import lustre/element/html.{div, form, h1, input, text}
import lustre_hx as hx
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
          input([
            class("search-input"),
            type_("search"),
            name("search"),
            hx.post("/hx/doctolib/search"),
            hx.trigger([hx.Event("input changed delay:500ms, search", [])]),
            hx.target(hx.CssSelector("#search-results")),
          ]),
          div([id("search-results")], []),
        ]),
      ]),
    ]),
    200,
  )
}

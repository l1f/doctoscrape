import lustre/element/html.{h1, text}
import web/home.{home}
import web/layouts
import web/middleware.{middleware}
import web/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> home(req)
    _ -> not_found_view(req)
  }
}

fn not_found_view(req: Request) -> Response {
  layouts.base_layout(req, h1([], [text("Page Not Found")]), 404)
}

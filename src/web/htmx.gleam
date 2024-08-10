import doctoscrape/doctolib.{type Autocomplete}
import gleam/http.{Post}
import gleam/list
import gleam/result
import lustre/element.{type Element}
import lustre/element/html.{div, text}
import web/layouts
import web/web
import wisp.{type Request, type Response}

pub fn hx_search_results(req: Request) -> Response {
  case req.method {
    Post -> hx_search_results_view(req)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn hx_search_results_view(req: Request) -> Response {
  use formdata <- wisp.require_form(req)
  let search_result = {
    use search_value <- result.try(
      list.key_find(formdata.values, "search")
      |> result.map_error(web.ClientError),
    )
    use search_result <- result.try(
      doctolib.get_autocomplete(search_value)
      |> result.map_error(web.DoctolibRemoteError),
    )

    search_result |> search_result_to_html() |> Ok()
  }

  case search_result {
    Ok(result) -> layouts.partial_layout(req, result, 200)
    Error(_) -> layouts.partial_layout(req, text("error"), 400)
  }
}

fn search_result_to_html(result: String) -> Element(a) {
  let first = {
    use autocomplete <- result.try(
      doctolib.decode_autocomplete(result)
      |> result.map_error(web.DoctolibApiError),
    )

    use first <- result.try(
      list.first(autocomplete.profiles) |> result.map_error(web.ClientError),
    )

    Ok(first)
  }
  case first {
    Ok(e) -> div([], [text(e.name)])
    Error(_) -> div([], [])
  }
}

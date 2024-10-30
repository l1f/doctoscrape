import lustre/attribute
import doctoscrape/doctolib.{type Autocomplete, type Profile}
import gleam/http.{Post}
import gleam/int
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
    // TODO: 400 is not correct in any case, the doctolib api can response wrong things
    // in that case it should return a internal server error
    Error(_) -> layouts.partial_layout(req, text("error"), 400)
  }
}

fn search_result_to_html(result: String) -> Element(a) {
  let html_profiles = {
    use autocomplete <- result.try(
      doctolib.decode_autocomplete(result)
      |> result.map_error(web.DoctolibApiError),
    )

    profiles_to_html(autocomplete.profiles) |> Ok()
  }

  case html_profiles {
    Ok(html) -> html
    Error(_) -> div([], [])
  }
}

fn profiles_to_html(profiles: List(Profile)) -> Element(a) {
  profiles
  |> list.map(profile_to_html)
  |> div([], _)
}

fn profile_to_html(profile: Profile) -> Element(a) {
  div([attribute.class("search-profile")], [
    div([], [text("Stadt: "), text(profile.city)]),
    div([], [text("Type: "), text(profile.owner_type)]),
    div([], [text("Value: "), text(int.to_string(profile.value))]),
    div([], [text("Name: "), text(profile.name)]),
    div([], [text("Name mit title: "), text(profile.name_with_title)]),
    div([], [text("Haupt Name: "), text(profile.main_name)]),
    div([], [text("cpi: "), text(profile.cloudinary_public_id)]),
    div([], [text("kind: "), text(profile.kind)]),
    div([], [text("link: "), text(profile.link)]),
  ])
}

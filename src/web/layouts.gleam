import lustre/attribute.{href, rel, src}
import lustre/element.{type Element}
import lustre/element/html.{body, head, html, link, main, script, title}
import wisp.{type Request, type Response}

pub fn base_layout(_req: Request, children: Element(a), status: Int) -> Response {
  let html =
    html([], [
      head([], [
        title([], "Doctoscrape"),
        link([rel("stylesheet"), href("/static/style.css")]),
        script([src("https://unpkg.com/htmx.org@2.0.1")], ""),
      ]),
      body([], [main([], [children])]),
    ])

  let response = element.to_document_string_builder(html)
  wisp.html_response(response, status)
}

pub fn partial_layout(
  _req: Request,
  children: Element(a),
  status: Int,
) -> Response {
  let response = element.to_string_builder(children)
  wisp.html_response(response, status)
}

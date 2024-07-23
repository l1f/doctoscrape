import gleam/dynamic.{type Decoder}
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/int

pub type Header {
  Header(key: String, value: String)
}

pub const default_headers = [
  Header("accept", "application/json"),
  Header("accept-language", "en-US,en;q=0.9,de;q=0.8"),
  Header("content-type", "application/json; charset-utf-8"),
]

pub const endpoint = "https://doctolib.de/availabilities.json"

pub type Insurance {
  Public
  Private
}

fn insurance_to_string(insurance: Insurance) -> String {
  case insurance {
    Public -> "public"
    Private -> "private"
  }
}

pub type Availability {
  // TODO: support subsitution and appoitment_request_slots
  Availability(date: String, slots: List(String))
}

fn availability_decoder() -> Decoder(Availability) {
  dynamic.decode2(
    Availability,
    dynamic.field("date", dynamic.string),
    dynamic.field("slots", dynamic.list(dynamic.string)),
  )
}

pub type AvailabilityResponse {
  AvailabilityResponse(availabilities: List(Availability), total: Int)
}

pub fn availability_response_decorder() -> Decoder(AvailabilityResponse) {
  dynamic.decode2(
    AvailabilityResponse,
    dynamic.field("availabilities", dynamic.list(availability_decoder())),
    dynamic.field("total", dynamic.int),
  )
}

pub type AvailabilityRequest {
  AvailabiliyRequest(
    visit_motives: List(Int),
    agendas: List(Int),
    practices: List(Int),
    insurance: Insurance,
  )
}

fn int_list_to_string(list: List(Int), result: String) -> String {
  case list {
    [] -> result
    [last] -> int_list_to_string([], result <> int.to_string(last))
    [item, ..rest] -> int_list_to_string(rest, int.to_string(item) <> "-")
  }
}

pub fn get_availabilities(
  availability_request: AvailabilityRequest,
) -> Result(String, dynamic.Dynamic) {
  let assert Ok(doctolib_request) = request.to(endpoint)
  let doctolib_request = build_uri(doctolib_request, availability_request)
  let doctolib_request = build_headers(doctolib_request, default_headers)

  case httpc.send(doctolib_request) {
    Ok(response) -> Ok(response.body)
    Error(err) -> Error(err)
  }
}

fn build_uri(
  request: Request(String),
  availability_request: AvailabilityRequest,
) -> Request(String) {
  let int_list_to_string = int_list_to_string(_, "")

  request.set_query(request, [
    #("start_date", "2024-08-16"),
    #(
      "visit_motive_ids",
      int_list_to_string(availability_request.visit_motives),
    ),
    #("agenda_ids", int_list_to_string(availability_request.agendas)),
    #("practice", int_list_to_string(availability_request.practices)),
    #("insurance_sector", insurance_to_string(availability_request.insurance)),
    #("limit", "15"),
  ])
}

fn build_headers(
  request: Request(String),
  headers: List(Header),
) -> Request(String) {
  case headers {
    [] -> request
    [header, ..rest] -> {
      let request = request.set_header(request, header.key, header.value)
      build_headers(request, rest)
    }
  }
}

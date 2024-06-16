import gleam/dynamic.{type Decoder}
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json

type Insurance {
  Public
  Private
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

fn availability_response_decorder() -> Decoder(AvailabilityResponse) {
  dynamic.decode2(
    AvailabilityResponse,
    dynamic.field("availabilities", dynamic.list(availability_decoder())),
    dynamic.field("total", dynamic.int),
  )
}

fn insurance_to_string(insurance: Insurance) -> String {
  case insurance {
    Public -> "public"
    Private -> "private"
  }
}

type AvailabilityRequest {
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

pub fn main() {
  io.println("Hello from doctoscrape!")
  let assert Ok(body) =
    get_availabilities(AvailabiliyRequest([], [], [], Public))

  let assert Ok(data) = json.decode(from: body, using: dynamic.dynamic)
  let assert Ok(decoded_data) = availability_response_decorder()(data)

  io.debug(decoded_data)
}

const default_headers = [
  Header("authority", "www.doctilb.de"), Header("accept", "application/json"),
  Header("accept-language", "en-US,en;q=0.9,de;q=0.8"),
  Header("content-type", "application/json; charset-utf-8"),
]

fn get_availabilities(
  request: AvailabilityRequest,
) -> Result(String, dynamic.Dynamic) {
  let uri = build_uri(request)
  let assert Ok(request) = request.to("https://www.doctolib.de/" <> uri)

  let request = build_headers(request, default_headers)
  case httpc.send(request) {
    Ok(response) -> Ok(response.body)
    Error(err) -> Error(err)
  }
}

fn build_uri(ar: AvailabilityRequest) -> String {
  "availabilities.json?start_date="
  <> "2024-08-16"
  <> "&visit_motive_ids="
  <> int_list_to_string(ar.visit_motives, "")
  <> "&agenda_ids="
  <> int_list_to_string(ar.agendas, "")
  <> "&practice_ids="
  <> int_list_to_string(ar.practices, "")
  <> "&insurance_sector="
  <> insurance_to_string(ar.insurance)
  <> "&limit=15"
}

type Header {
  Header(key: String, value: String)
}

fn build_headers(
  request: request.Request(String),
  headers: List(Header),
) -> request.Request(String) {
  case headers {
    [] -> request
    [header, ..rest] -> {
      let request = request.set_header(request, header.key, header.value)
      build_headers(request, rest)
    }
  }
}

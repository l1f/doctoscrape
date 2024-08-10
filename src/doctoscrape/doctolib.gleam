import gleam/dynamic.{type Decoder}
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result

pub type DoctolibError {
  APIError
}

pub type APIError {
  DecodingError(json.DecodeError)
  DecodingListError(List(dynamic.DecodeError))
}

pub type Header {
  Header(key: String, value: String)
}

pub const default_headers = [
  Header("accept", "application/json"),
  Header("accept-language", "en-US,en;q=0.9,de;q=0.8"),
  Header("content-type", "application/json; charset-utf-8"),
]

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

pub const faq_details_endpint = "https://www.doctolib.de/profiles/75919/faq_details.json"

// ------- Autocomplete 

pub const autocomplete_endpoint = "https://doctolib.de/api/searchbar/autocomplete.json"

pub type Profile {
  Profile(
    city: String,
    owner_type: String,
    value: Int,
    name: String,
    name_with_title: String,
    main_name: String,
    cloudinary_public_id: String,
    kind: String,
    link: String,
  )
}

fn profile_decoder() -> Decoder(Profile) {
  dynamic.decode9(
    Profile,
    dynamic.field("city", dynamic.string),
    dynamic.field("owner_type", dynamic.string),
    dynamic.field("value", dynamic.int),
    dynamic.field("name", dynamic.string),
    dynamic.field("name_with_title", dynamic.string),
    dynamic.field("main_name", dynamic.string),
    dynamic.field("cloudinary_public_id", dynamic.string),
    dynamic.field("kind", dynamic.string),
    dynamic.field("link", dynamic.string),
  )
}

pub type Autocomplete {
  Autocomplete(
    profiles: List(Profile),
    specialities: List(String),
    organization_statuses: List(String),
  )
}

pub fn autocomplete_decoder() -> Decoder(Autocomplete) {
  dynamic.decode3(
    Autocomplete,
    dynamic.field("profiles", dynamic.list(profile_decoder())),
    dynamic.field("specialities", dynamic.list(dynamic.string)),
    dynamic.field("organization_statuses", dynamic.list(dynamic.string)),
  )
}

pub fn decode_autocomplete(data: String) -> Result(Autocomplete, APIError) {
  use data <- result.try(
    json.decode(data, dynamic.dynamic) |> result.map_error(DecodingError)
  )
  use autocomplete <- result.try(
    autocomplete_decoder()(data) |> result.map_error(DecodingListError)
  )

  Ok(autocomplete)
}

pub fn get_autocomplete(search_term: String) -> Result(String, DoctolibError) {
  // Because i assume the URL from the `autocomplete_endpoint` cost 
  // is always correct formatted, it is ok to use assert Ok()
  let assert Ok(doctolib_request) = request.to(autocomplete_endpoint)

  let doctolib_request =
    // TODO: Sanitize user input
    request.set_query(doctolib_request, [#("search", search_term)])
    |> build_headers(default_headers)

  case httpc.send(doctolib_request) {
    Ok(response) -> Ok(response.body)
    Error(_) -> Error(APIError)
  }
}

// ------- Availabilites

pub const availabilities_endpoint = "https://doctolib.de/availabilities.json"

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
) -> Result(String, DoctolibError) {
  // Because i assume the URL from the `availabilities_endpoint` const 
  // is always correct formatted, it is ok to use assert Ok()
  let assert Ok(doctolib_request) = request.to(availabilities_endpoint)

  let doctolib_request =
    build_availabilities_uri(doctolib_request, availability_request)
    |> build_headers(default_headers)

  case httpc.send(doctolib_request) {
    Ok(response) -> Ok(response.body)
    Error(_) -> Error(APIError)
  }
}

fn build_availabilities_uri(
  request: Request(String),
  availability_request: AvailabilityRequest,
) -> Request(String) {
  let int_list_to_string = int_list_to_string(_, "")

  request.set_query(request, [
    // TODO: make this variable
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

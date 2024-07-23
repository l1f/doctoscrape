import doctoscrape/doctolib
import gleam/dynamic
import gleam/io
import gleam/json

pub fn main() {
  io.println("Hello from doctoscrape!")

  let assert Ok(body) =
    doctolib.get_availabilities(doctolib.AvailabiliyRequest(
      [],
      [],
      [],
      doctolib.Public,
    ))
  let assert Ok(data) = json.decode(from: body, using: dynamic.dynamic)
  let assert Ok(decoded_data) = doctolib.availability_response_decorder()(data)

  io.debug(decoded_data)
}

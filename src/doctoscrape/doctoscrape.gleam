pub type Header {
  Header(key: String, value: String)
}

pub const default_headers = [
  Header("accept", "application/json"),
  Header("accept-language", "en-US,en;q=0.9,de;q=0.8"),
  Header("content-type", "application/json; charset-utf-8"),
]

pub const endpoint = "https://doctolib.de/availabilities.json"

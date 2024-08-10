import doctoscrape/doctolib

pub type AppError {
  DoctolibRemoteError(doctolib.DoctolibError)
  DoctolibApiError(doctolib.APIError)
  ClientError(Nil)
}


pub type Context {
  Context(static_directory: String)
}

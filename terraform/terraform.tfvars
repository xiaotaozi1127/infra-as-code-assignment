prefix     = "tw-infra-taohui"
region     = "ap-southeast-2"
stage_name = "default"
webpages = [
  {
    name = "index.html"
  },
  {
    name = "error.html"
  }
]
functions = [
  {
    name   = "register_user",
    method = "POST",
  },
  {
    name   = "verify_user",
    method = "GET",
  }
]

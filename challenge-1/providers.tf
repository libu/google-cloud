provider "google" {
  project     = "libu-playground-3"
  region      = "us-west1"
  zone   = "us-west1-a"
}

provider "google-beta" {
     project     = "libu-playground-3"
  region = "us-west1"
  zone   = "us-west1-a"
}

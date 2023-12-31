variable "zone" {
  description = "Yandex Cloud zone"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "cloud_id" {
  description = "Cloud ID"
  type        = string
  default     = "b1g2i3ab2uo1i452bsnm"
}

variable "folder_id" {
  description = "Folder ID"
  type        = string
  default     = "b1ge6lot4hn9qtfho732"
}

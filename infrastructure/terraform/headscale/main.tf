resource "headscale_policy" "main" {
  policy = file("${path.module}/acl.hujson")
}

resource "headscale_user" "homelab_admins" {
  name = "homelab-admins"
}

resource "headscale_user" "infra" {
  name = "infra"
}

resource "headscale_user" "homelab_users" {
  name = "homelab-users"
}

resource "headscale_pre_auth_key" "fleet_client_key" {
  user           = headscale_user.homelab_users.id
  reusable       = true
  ephemeral      = false
  time_to_expire = "365d" # 1 year key
}





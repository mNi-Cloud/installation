resource "keycloak_realm" "cloud" {
  realm = "cloud"
  enabled = true

  login_theme = "keycloak-custom-theme"
}

resource "keycloak_realm_events" "realm_events" {
  realm_id = keycloak_realm.cloud.id

  events_listeners = [
    "jboss-logging",
    "mni-registration-hook",
  ]
}

resource "keycloak_realm_user_profile" "userprofile" {
  realm_id = keycloak_realm.cloud.id

  attribute {
    name = "username"
    display_name = "$${username}"

    validator {
      name = "length"
      config = {
        min = 4
        max = 255
      }
    }

    validator {
      name = "username-prohibited-characters"
    }

    validator {
      name = "up-username-not-idn-homograph"
    }

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

  }

  attribute {
    name = "email"
    display_name = "$${email}"

    validator {
      name = "email"
    }

    validator {
      name = "length"
      config = {
        max = 255
      }
    }

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }

  attribute {
    name = "firstName"
    display_name = "$${firstName}"

    validator {
      name = "length"
      config = {
        max = 255
      }
    }

    validator {
      name = "person-name-prohibited-characters"
    }

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }

  attribute {
    name = "lastName"
    display_name = "$${lastName}"


    validator {
      name = "length"
      config = {
        max = 255
      }
    }

    validator {
      name = "person-name-prohibited-characters"
    }

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }

  attribute {
    name = "root"

    validator {
      name = "options"
      config = {
        options = jsonencode(["true", "false"])
      }
    }

    permissions {
      view = ["admin"]
      edit = ["admin"]
    }
  }

  attribute {
    name = "namespace"

    permissions {
      view = ["admin"]
      edit = ["admin"]
    }
  }

  group {
    name = "user-metadata"
    display_header = "User metadata"
    display_description = "Attributes, which refer to user metadata"
  }
}

resource "keycloak_openid_client" "direct-login" {
  realm_id            = keycloak_realm.cloud.id
  client_id           = "direct-login"
  enabled             = true

  standard_flow_enabled = false
  direct_access_grants_enabled = true

  access_type = "CONFIDENTIAL"
}

resource "keycloak_openid_client" "mni-cli" {
  realm_id            = keycloak_realm.cloud.id
  client_id           = "mni-cli"
  enabled             = true

  standard_flow_enabled = true
  direct_access_grants_enabled = true

  valid_redirect_uris = [
    "http://localhost:51820/auth/callback"
  ]

  access_type = "PUBLIC"
}

data "keycloak_openid_client_scope" "profile" {
  realm_id               = keycloak_realm.cloud.id
  name                   = "profile"
}

resource "keycloak_openid_user_attribute_protocol_mapper" "profile-namespace" {
  realm_id        = keycloak_realm.cloud.id
  client_scope_id = data.keycloak_openid_client_scope.profile.id

  name            = "namespace mapper"

  user_attribute  = "namespace"
  claim_name      = "namespace"
}

resource "keycloak_openid_user_attribute_protocol_mapper" "profile-root" {
  realm_id        = keycloak_realm.cloud.id
  client_scope_id = data.keycloak_openid_client_scope.profile.id

  name            = "root flag mapper"

  user_attribute  = "root"
  claim_name      = "root"
  claim_value_type = "boolean"
}


data "keycloak_openid_client_scope" "roles" {
  realm_id               = keycloak_realm.cloud.id
  name                   = "roles"
}


resource "keycloak_openid_user_realm_role_protocol_mapper" "roles" {
  realm_id        = keycloak_realm.cloud.id
  client_scope_id = data.keycloak_openid_client_scope.roles.id

  name = "roles"
  claim_name = "roles"

  multivalued = true
  add_to_id_token = true
  add_to_access_token = true
  add_to_userinfo = false
}

resource "keycloak_role" "service" {
  realm_id    = keycloak_realm.cloud.id
  name        = "service"
}

resource "keycloak_role" "user" {
  realm_id    = keycloak_realm.cloud.id
  name        = "user"
}

locals {
  users = yamldecode(file("${path.module}/users.yaml"))
}

resource "keycloak_user" "service_user" {
  for_each = { for user in local.users.service_users : user.username => user }

  realm_id   = keycloak_realm.cloud.id
  username   = each.key

  enabled    = true

  email      = "${each.key}@example.com"
  email_verified = true

  initial_password {
    value     = each.value.password
    temporary = false
  }
}

resource "keycloak_user_roles" "service_user_roles" {
  for_each = { for user in local.users.service_users : user.username => user }

  realm_id = keycloak_realm.cloud.id
  user_id = keycloak_user.service_user[each.key].id

  role_ids = [
    keycloak_role.service.id,
  ]
}


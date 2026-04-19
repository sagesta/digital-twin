resource "random_id" "storage" {
  byte_length = 2
}

resource "random_id" "openai_sub" {
  byte_length = 2
}

# Suffix for Cognitive Services account *name* (separate from custom_subdomain_name) so new
# creates do not collide with a soft-deleted account (409 FlagMustBeSetForRestore).
resource "random_id" "openai_account" {
  byte_length = 2
}

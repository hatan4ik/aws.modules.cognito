# A Cognito user pool needs no VPC or other infrastructure prerequisite, so
# the only disposable fixture the integration suites need is a random suffix
# that keeps concurrent runs from colliding on the pool name.
resource "random_id" "suffix" {
  byte_length = 3
}

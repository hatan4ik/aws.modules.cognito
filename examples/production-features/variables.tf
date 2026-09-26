variable "region" {
  description = "AWS region the user pool is created in."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Lowercase Cognito user-pool name."
  type        = string
}

variable "pre_sign_up_lambda_arn" {
  description = "ARN of the Lambda function invoked on the PreSignUp trigger."
  type        = string
}

variable "post_confirmation_lambda_arn" {
  description = "ARN of the Lambda function invoked on the PostConfirmation trigger."
  type        = string
}

variable "ses_identity_arn" {
  description = "ARN of the verified SES identity used to send account emails."
  type        = string
}

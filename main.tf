provider "aws" {
	access_key = "${var.access_key}"
	secret_key = "${var.secret_key}"
	region = "us-east-1"
}

resource "aws_iam_role" "iam_for_webhook-lambda" {
    name = "iam_for_webhook-lambda"
    assume_role_policy = "${file("${path.module}/policies/assumeRolePolicy.json")}"
}

resource "aws_iam_role_policy" "iam_policy_for_webhook_lambda" {
    name = "iam_policy_for_webhook_lambda"
	role = "${aws_iam_role.iam_for_webhook-lambda.id}"
    policy = "${file("${path.module}/policies/assumePolicy.json")}"
}

resource "aws_lambda_function" "webhook_lambda" {
	filename = "codecommit-webhook.zip"
	function_name = "codecommit-webhook"
	role = "${aws_iam_role.iam_for_webhook-lambda.arn}"
	handler = "codecommit-webhook.handler"
	runtime = "nodejs4.3"
	source_code_hash = "${base64sha256(file("codecommit-webhook.zip"))}"
}

resource "aws_lambda_permission" "allow_from_lambda" {
	statement_id = "AllowExecutionFromLambda"
	action = "lambda:InvokeFunction"
	function_name = "${aws_lambda_function.webhook_lambda.arn}"
	principal = "codecommit.amazonaws.com"
}
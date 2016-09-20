provider "aws" {
	access_key = "${var.access_key}"
	secret_key = "${var.secret_key}"
	region = "us-east-1"
}

resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda"
    assume_role_policy = "${file("${path.module}/assumeRolePolicy.json")}"
}

resource "aws_sns_topic" "webhook-sns" {
	name = "webhook-sns-topic"
}

resource "aws_lambda_function" "webhook-lambda" {
	filename = "codecommit-webhook-payload.zip"
	function_name = "codecommit-webhook"
	role = "${aws_iam_role.iam_for_lambda.arn}"
	handler = "codecommit-webhook.handler"
	runtime = "nodejs4.3"
	source_code_hash = "${base64sha256(file("codecommit-webhook-payload.zip"))}"
}

resource "aws_sns_topic_subscription" "webhook-sns-subscription" {
	depends_on = ["aws_lambda_function.webhook-lambda"]
	topic_arn = "${aws_sns_topic.webhook-sns.arn}"
	protocol = "lambda"
	endpoint = "${aws_lambda_function.webhook-lambda.arn}"
}

resource "aws_lambda_permission" "with_sns" {
	statement_id = "AllowExecutionFromSNS"
	action = "lambda:InvokeFunction"
	function_name = "${aws_lambda_function.webhook-lambda.arn}"
	principal = "sns.amazonaws.com"
	source_arn = "${aws_sns_topic.webhook-sns.arn}"
}
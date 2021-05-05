resource "aws_iam_user" "saeed" {
  name = "saeed-500"
  path = "/system/"

}

resource "aws_iam_access_key" "saeed" {
  user = aws_iam_user.saeed.name
}
resource "aws_iam_user_policy" "saeed" {
  name = "test"
  user = aws_iam_user.saeed.name

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}
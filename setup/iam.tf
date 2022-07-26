data "aws_iam_policy_document" "vault_auth_policy" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "vault_auth_policy" {
  name   = "vault-auth-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.vault_auth_policy.json
}

resource "aws_iam_user" "vault_auth" {
  name = "vault-talks-iam-user"
}

resource "aws_iam_user_policy_attachment" "vault_auth_policy_attachment" {
  user       = aws_iam_user.vault_auth.name
  policy_arn = aws_iam_policy.vault_auth_policy.arn
}

resource "aws_iam_access_key" "vault_auth" {
  user = aws_iam_user.vault_auth.name
}

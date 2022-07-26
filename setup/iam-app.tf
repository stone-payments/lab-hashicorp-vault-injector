resource "aws_iam_role" "iam_assumable_role_with_web_identity" {
  name               = "app-example-iam-auth"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::***REMOVED***:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/[ID AQUI]"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/[ID AQUI]:sub": "system:serviceaccount:app-example-iam-auth:app-example-iam-auth"
                    # Substituir pelo ID do cluster EKS
                }
            }
        }
    ]
  })
}


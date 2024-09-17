resource "aws_iam_role" "dev_role" {
  name = "${var.username}sDevEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.username}sDevEC2Role"
    User = var.username
  }
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "dev_instance_profile" {
  name = "DevEC2Profile"
  role = aws_iam_role.dev_role.name

  tags = {
    Name = "${var.username}sDevEC2Profile"
    User = var.username
  }
}

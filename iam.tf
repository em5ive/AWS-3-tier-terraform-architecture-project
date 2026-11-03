# EC2 is trusted to assume this role.
resource "aws_iam_role" "ec2_ssm" {
  name = "ec2_ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Launch templates attach the role through an instance profile.
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "ec2_ssm"
  role = aws_iam_role.ec2_ssm.name
}

resource "aws_key_pair" "ssh_key" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}
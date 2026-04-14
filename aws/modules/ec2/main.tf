################################################################################
# MODULE: EC2
# Creates:
#   - Security group (SSH + Docker port)
#   - EC2 instance with Docker pre-installed via user_data
#   - SSM IAM profile attached
################################################################################
provider "aws" {
    region = "ap-south-2"
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "link_monitor" {
  name        = "${var.project_name}-sg"
  description = "Security group for ${var.project_name} EC2"

  # SSH — tighten this to your IP in production
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # All outbound allowed (needed for Docker pull, SSM, Telegram API)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = { Name = "${var.project_name}-sg" }
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────
resource "aws_instance" "link_monitor" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = var.ec2_iam_role_name
  vpc_security_group_ids = [aws_security_group.link_monitor.id]

  # Pre-install Docker + SSM agent + clone repo on first boot
  user_data = <<-EOF
#!/bin/bash
set -e

# Update system
dnf update -y

# Install Docker
dnf install -y docker git

# Start Docker
systemctl start docker
systemctl enable docker

# Allow ec2-user to use Docker
usermod -aG docker ec2-user

# Install SSM Agent (already installed usually)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Clone repo
if [ -n "${var.github_repo_url}" ]; then
  sudo -u ec2-user git clone ${var.github_repo_url} /home/ec2-user/${var.project_name} \
    >> /var/log/user-data.log 2>&1 || true
fi

echo "Bootstrap complete" >> /var/log/user-data.log
EOF

  tags = {
    Name    = "${var.project_name}-server"
    Project = var.project_name
  }

}

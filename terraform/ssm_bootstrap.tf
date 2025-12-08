resource "aws_ssm_document" "chatbot_bootstrap" {
  name          = "${var.project}-chatbot-bootstrap"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Install Docker, clone chatbot repo, build & run Docker container on port 8080"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "BootstrapChatbot"
        inputs = {
          runCommand = [
            "set -eux",

            "echo '=== Detect package manager (apt/yum) ==='",
            "if command -v apt-get >/dev/null 2>&1; then",
            "  PM=apt",
            "elif command -v yum >/dev/null 2>&1; then",
            "  PM=yum",
            "else",
            "  echo 'No supported package manager (apt or yum) found' >&2",
            "  exit 1",
            "fi",

            "echo '=== Install Docker + Git if missing ==='",
            "if [ \"$PM\" = \"apt\" ]; then",
            "  apt-get update -y",
            "  apt-get install -y docker.io git",
            "  systemctl enable --now docker || true",
            "else",
            "  yum install -y docker git",
            "  systemctl enable --now docker || true",
            "fi",

            "echo '=== Choose working home directory ==='",
            "if [ -d /home/ubuntu ]; then",
            "  cd /home/ubuntu",
            "elif [ -d /home/ec2-user ]; then",
            "  cd /home/ec2-user",
            "else",
            "  cd /root",
            "fi",

            "echo '=== Clone or update chatbot repo ==='",
           
            "if [ ! -d cloud-computing-chatbot ]; then",
            "  git clone https://github.com/Terabyite/cloud-computing-chatbot.git",
            "fi",
            "cd cloud-computing-chatbot",
            "git pull || true",

            "echo '=== Build Docker image ==='",
            "docker rm -f chatbot || true",
            "docker build -t chatbot:latest .",

            "echo '=== Run Docker container on 8080 ==='",
            "docker run -d --name chatbot -p 8080:8080 --restart unless-stopped chatbot:latest",

            "echo '=== Check port 8080 (local) ==='",
            "sleep 5",
            "curl -v http://localhost:8080/ || true",

            "echo '=== Bootstrap finished ==='"
          ]
        }
      }
    ]
  })
}


resource "aws_ssm_association" "chatbot_bootstrap" {
  name = aws_ssm_document.chatbot_bootstrap.name

  targets {
    key    = "tag:ManagedBy"
    values = ["github-actions"]
  }


  compliance_severity = "HIGH"
}
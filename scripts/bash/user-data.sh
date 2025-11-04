#!/usr/bin/env bash
set -euxo pipefail

# AL2023 = dnf
dnf -y update
dnf -y install nodejs

# App Node Hello World (port 80)
install -d -m 0755 /opt/sample-app
cat > /opt/sample-app/app.js <<'APP'
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello, World!\n');
});
const port = process.env.PORT || 80;
server.listen(port, () => console.log(`Listening on port ${port}`));
APP

# Service systemd pour démarrer/relancer l'app
cat > /etc/systemd/system/sample-app.service <<'UNIT'
[Unit]
Description=Node sample app
After=network.target

[Service]
Environment=PORT=80
ExecStart=/usr/bin/node /opt/sample-app/app.js
Restart=always
User=root
StandardOutput=append:/var/log/sample-app.log
StandardError=append:/var/log/sample-app.err

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now sample-app.service

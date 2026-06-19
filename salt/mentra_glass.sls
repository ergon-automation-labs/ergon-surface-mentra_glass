# Salt state file for deploying ergon-surface-mentra_glass
# Usage: salt-call state.apply mentra_glass

# App configuration
{%- set app_name = 'mentra_glass' %}
{%- set app_user = 'deploy' %}
{%- set app_group = 'deploy' %}
{%- set app_home = '/opt/ergon/surfaces/mentra_glass' %}
{%- set app_port = 4000 %}
{%- set nats_host = pillar.get('nats:primary_host', 'localhost') %}
{%- set nats_port = pillar.get('nats:primary_port', 4222) %}
{%- set mentra_os_api_key = pillar.get('mentra_glass:api_key', '') %}

# Ensure deploy user exists
mentra_glass_user:
  user.present:
    - name: {{ app_user }}
    - home: /home/{{ app_user }}
    - shell: /bin/bash
    - groups:
      - {{ app_group }}

# Create app directory
mentra_glass_dir:
  file.directory:
    - name: {{ app_home }}
    - user: {{ app_user }}
    - group: {{ app_group }}
    - mode: 755
    - makedirs: True

# Clone or update repository
mentra_glass_repo:
  git.latest:
    - name: https://github.com/yourusername/ergon-surface-mentra_glass-elixir.git
    - target: {{ app_home }}
    - user: {{ app_user }}
    - force: True
    - require:
      - file: mentra_glass_dir

# Install Elixir dependencies
mentra_glass_deps:
  cmd.run:
    - name: mix deps.get && mix deps.compile
    - cwd: {{ app_home }}
    - user: {{ app_user }}
    - require:
      - git: mentra_glass_repo

# Compile assets
mentra_glass_assets:
  cmd.run:
    - name: mix assets.deploy
    - cwd: {{ app_home }}
    - user: {{ app_user }}
    - require:
      - cmd: mentra_glass_deps

# Create systemd service file
mentra_glass_service:
  file.managed:
    - name: /etc/systemd/system/mentra-glass.service
    - contents: |
        [Unit]
        Description=Mentra Glass - Bot Army Web Surface
        After=network.target
        StartLimitIntervalSec=0

        [Service]
        Type=notify
        Restart=always
        RestartSec=10
        StandardOutput=journal
        StandardError=journal
        SyslogIdentifier=mentra-glass
        User={{ app_user }}
        WorkingDirectory={{ app_home }}
        Environment="PATH=/home/{{ app_user }}/.local/share/mise/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
        Environment="MIX_ENV=prod"
        Environment="PORT={{ app_port }}"
        Environment="NATS_HOST={{ nats_host }}"
        Environment="NATS_PORT={{ nats_port }}"
        Environment="PACKAGE_NAME=com.ergon.mentra-glass"
        Environment="MENTRA_OS_API_KEY={{ mentra_os_api_key }}"
        EnvironmentFile=-/etc/default/mentra-glass
        ExecStart=/home/{{ app_user }}/.local/share/mise/shims/mix phx.server
        ExecStop=/bin/kill -TERM $MAINPID
        TimeoutStopSec=30

        [Install]
        WantedBy=multi-user.target
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: mentra_glass_assets

# Create environment file for additional config
mentra_glass_env:
  file.managed:
    - name: /etc/default/mentra-glass
    - contents: |
        # Mentra Glass environment configuration
        # Add any additional env vars here
    - user: root
    - group: root
    - mode: 644

# Reload systemd daemon
mentra_glass_systemd_reload:
  cmd.run:
    - name: systemctl daemon-reload
    - require:
      - file: mentra_glass_service

# Enable and start service
mentra_glass_service_enable:
  service.enabled:
    - name: mentra-glass
    - require:
      - cmd: mentra_glass_systemd_reload

mentra_glass_service_running:
  service.running:
    - name: mentra-glass
    - enable: True
    - watch:
      - git: mentra_glass_repo
      - cmd: mentra_glass_assets

# Nginx reverse proxy configuration (optional, for HTTPS)
nginx_mentra_glass_config:
  file.managed:
    - name: /etc/nginx/sites-available/mentra-glass
    - contents: |
        upstream mentra_glass_backend {
          server 127.0.0.1:{{ app_port }};
        }

        server {
          listen 443 ssl http2;
          server_name mentra-glass.yourdomain.com;

          ssl_certificate /etc/letsencrypt/live/mentra-glass.yourdomain.com/fullchain.pem;
          ssl_certificate_key /etc/letsencrypt/live/mentra-glass.yourdomain.com/privkey.pem;
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers HIGH:!aNULL:!MD5;
          ssl_prefer_server_ciphers on;

          client_max_body_size 10M;

          location / {
            proxy_pass http://mentra_glass_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_buffering off;
          }
        }

        server {
          listen 80;
          server_name mentra-glass.yourdomain.com;
          return 301 https://$server_name$request_uri;
        }
    - user: root
    - group: root
    - mode: 644

# Enable nginx config
nginx_mentra_glass_enable:
  file.symlink:
    - name: /etc/nginx/sites-enabled/mentra-glass
    - target: /etc/nginx/sites-available/mentra-glass
    - force: True
    - require:
      - file: nginx_mentra_glass_config

# Reload nginx
nginx_reload:
  cmd.run:
    - name: nginx -t && systemctl reload nginx
    - require:
      - file: nginx_mentra_glass_enable

# Health check endpoint
mentra_glass_health_check:
  cmd.run:
    - name: sleep 5 && curl -f http://localhost:{{ app_port }}/api/health || exit 1
    - require:
      - service: mentra_glass_service_running

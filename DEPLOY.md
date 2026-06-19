# Mentra Glass Deployment Guide

## Prerequisites

- Salt minion configured on target machine
- Elixir/OTP installed on target
- Nginx installed for reverse proxy (optional but recommended)
- SSL certificate for HTTPS (LetsEncrypt recommended)

## Deployment Steps

### 1. Prepare Pillar Data

Copy and customize the pillar configuration:

```bash
cp salt/mentra_glass.pillar.example /srv/pillar/mentra_glass.sls
```

Edit `/srv/pillar/mentra_glass.sls` with your:
- MENTRA_OS_API_KEY
- Repository URL
- Domain name
- NATS connection details

### 2. Apply Salt State

```bash
# Dry-run to preview changes
salt-call state.apply mentra_glass --test

# Apply the state
salt-call state.apply mentra_glass
```

### 3. Verify Deployment

```bash
# Check service status
systemctl status mentra-glass

# View logs
journalctl -u mentra-glass -f

# Test health endpoint
curl http://localhost:50000/api/health

# Test debug endpoint
curl http://localhost:50000/api/debug

# Check app.json manifest
curl http://localhost:50000/app.json
```

### 4. Configure MentraOS Console

Register the app in the MentraOS Developer Console:

- **Server URL**: `https://mentra-glass.yourdomain.com`
- **Webview URL**: `/webview`
- **Package Name**: `com.ergon.mentra-glass`
- **API Key**: From `.env` or pillar data

## Troubleshooting

### Service won't start

```bash
# Check logs for errors
journalctl -u mentra-glass -n 50

# Verify dependencies installed
/home/deploy/.local/share/mise/shims/mix deps.get

# Verify assets compiled
/home/deploy/.local/share/mise/shims/mix assets.deploy
```

### NATS connection issues

```bash
# Check NATS connectivity
curl -v nats://localhost:4222

# Verify environment variables
systemctl cat mentra-glass

# Check firewall
netstat -tuln | grep 4222
```

### Nginx proxy issues

```bash
# Test nginx config
nginx -t

# Check proxy logs
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

## Scaling Notes

- The Phoenix app is stateless, so you can run multiple instances behind a load balancer
- Use separate NATS connections per instance (each gets its own subscription)
- Nginx upstream block can be extended to multiple backends

## Rollback

To rollback to a previous version:

```bash
# Stop service
systemctl stop mentra-glass

# Checkout previous version
cd /opt/ergon/surfaces/mentra_glass
git checkout <commit-hash>

# Restart
systemctl start mentra-glass
```

## Monitoring

### Key Metrics to Watch

- Service uptime: `systemctl status mentra-glass`
- HTTP response times: Nginx logs at `/var/log/nginx/access.log`
- NATS connection health: Check logs for `"NATS.*error"`
- Memory usage: `ps aux | grep mentra-glass`

### Alerting

Configure Prometheus/Grafana to alert on:
- Service down (systemd)
- High response latency (>1s)
- NATS connection drops
- Error rate spikes

## Maintenance

### Update Application

```bash
# Pull latest code
cd /opt/ergon/surfaces/mentra_glass
git pull origin main

# Reinstall deps and recompile
mix deps.get
mix assets.deploy

# Restart service
systemctl restart mentra-glass
```

### Database Migrations (if added in future)

```bash
mix ecto.migrate
```

### Clear Cache

```bash
systemctl stop mentra-glass
rm -rf /opt/ergon/surfaces/mentra_glass/_build
systemctl start mentra-glass
```

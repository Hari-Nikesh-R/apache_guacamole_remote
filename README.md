# Apache Guacamole Docker Setup Guide

This guide will walk you through setting up Apache Guacamole using Docker Compose. Apache Guacamole is a clientless remote desktop gateway that supports standard protocols like VNC, RDP, and SSH.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup Instructions](#detailed-setup-instructions)
- [Database Initialization](#database-initialization)
- [Accessing Guacamole](#accessing-guacamole)
- [Default Credentials](#default-credentials)
- [Adding Remote Connections](#adding-remote-connections)
- [Managing the Docker Instance](#managing-the-docker-instance)
- [Troubleshooting](#troubleshooting)
- [Configuration Options](#configuration-options)

## Prerequisites

Before you begin, ensure you have the following installed on your system:

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher

To verify your installations:

```bash
docker --version
docker compose version
```

If you don't have Docker installed, visit:
- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
- [Docker Engine for Linux](https://docs.docker.com/engine/install/)

## Quick Start

If you're familiar with Docker and want to get started quickly:

```bash
# 1. Initialize the database
docker compose up -d postgres
docker compose exec postgres psql -U guacamole_user -d guacamole_db -f /docker-entrypoint-initdb.d/initdb.sql

# 2. Download and run the initialization script
docker compose exec postgres psql -U guacamole_user -d guacamole_db < /path/to/initdb.sql

# 3. Start all services
docker compose up -d

# 4. Access Guacamole
# Open http://localhost:8443/guacamole in your browser
# Default credentials: guacadmin / guacadmin
```

## Detailed Setup Instructions

### Step 1: Download Database Initialization Scripts

Apache Guacamole requires database initialization before first use. You need to download the SQL scripts from the official Guacamole repository.

1. **Download the PostgreSQL initialization script:**

```bash
# Create a directory for database scripts
mkdir -p db-init

# Download the PostgreSQL schema script
curl -L https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/001-create-schema.sql -o db-init/001-create-schema.sql

# Download the upgrade script (if needed)
curl -L https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/002-create-admin-user.sql -o db-init/002-create-admin-user.sql
```

**Alternative method using Docker:**

```bash
# Download using Docker (if curl is not available)
docker run --rm -v $(pwd)/db-init:/output guacamole/guacamole:latest /bin/sh -c "cp /opt/guacamole/postgresql/schema/*.sql /output/" || echo "Note: You may need to download manually"
```

### Step 2: Start the PostgreSQL Container

Start only the PostgreSQL container first to initialize the database:

```bash
docker compose up -d postgres
```

Wait for the database to be ready (check logs):

```bash
docker compose logs postgres
```

You should see a message like: `database system is ready to accept connections`

### Step 3: Initialize the Database Schema

Once PostgreSQL is running, you need to initialize the Guacamole database schema. You have two options:

#### Option A: Using Docker Exec (Recommended)

```bash
# Copy the SQL files into the container and execute
docker compose exec -T postgres psql -U guacamole_user -d guacamole_db < db-init/001-create-schema.sql
docker compose exec -T postgres psql -U guacamole_user -d guacamole_db < db-init/002-create-admin-user.sql
```

#### Option B: Using Docker Run (Alternative)

```bash
# Run the SQL scripts using a temporary PostgreSQL client
docker run --rm --network apache_guacamole_guacamole-network -v $(pwd)/db-init:/scripts postgres:15-alpine psql -h postgres -U guacamole_user -d guacamole_db -f /scripts/001-create-schema.sql
docker run --rm --network apache_guacamole_guacamole-network -v $(pwd)/db-init:/scripts postgres:15-alpine psql -h postgres -U guacamole_user -d guacamole_db -f /scripts/002-create-admin-user.sql
```

**Note:** If you encounter network name issues, check the actual network name with:
```bash
docker network ls
```

### Step 4: Start All Services

Now that the database is initialized, start all services:

```bash
docker compose up -d
```

This will start:
- PostgreSQL (database)
- guacd (Guacamole daemon)
- guacamole (web application)

### Step 5: Verify Services are Running

Check that all containers are running:

```bash
docker compose ps
```

You should see all three services with status "Up". Check the logs if needed:

```bash
# View logs for all services
docker compose logs

# View logs for a specific service
docker compose logs guacamole
docker compose logs guacd
docker compose logs postgres
```

## Database Initialization

The database initialization is a critical step. The Guacamole database schema must be created before the web application can start properly.

### Required SQL Scripts

You need the following SQL scripts from the Guacamole project:

1. **001-create-schema.sql**: Creates all database tables and structures
2. **002-create-admin-user.sql**: Creates the default administrator account

### Download Locations

The official SQL scripts are available at:
- **GitHub Repository**: https://github.com/apache/guacamole-client
- **Direct Path**: `extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/`

### Manual Download Steps

1. Visit: https://github.com/apache/guacamole-client/tree/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema
2. Download `001-create-schema.sql`
3. Download `002-create-admin-user.sql` (optional, creates default admin)
4. Save them in a `db-init` directory in your project folder

### Verification

After initialization, verify the schema was created:

```bash
docker compose exec postgres psql -U guacamole_user -d guacamole_db -c "\dt"
```

You should see a list of tables including `guacamole_user`, `guacamole_connection`, etc.

## Accessing Guacamole

### Web Interface

Once all services are running, access Guacamole at:

```
http://localhost:8443/guacamole
```

Or if accessing from another machine:

```
http://YOUR_SERVER_IP:8443/guacamole
```

### Default Credentials

**Important:** Change these credentials immediately after first login!

- **Username**: `guacadmin`
- **Password**: `guacadmin`

### First Login

1. Open your web browser
2. Navigate to `http://localhost:8443/guacamole`
3. You should see the Guacamole login page
4. Enter the default credentials
5. **Immediately change the password** after logging in:
   - Click on your username (top right)
   - Select "Settings"
   - Go to "Preferences" → "Change Password"

## Adding Remote Connections

After logging in, you can add remote desktop connections to access remote computers through your browser.

### Prerequisites for Remote Connections

Before creating a connection, ensure you have the following:

#### For RDP Connections:
1. **Remote Computer Requirements:**
   - The remote computer must be powered on and accessible on the network
   - **Windows**: Remote Desktop must be enabled (Settings → System → Remote Desktop)
   - **Linux**: An RDP server must be installed and running (e.g., xrdp)

2. **Network Connectivity:**
   - The Guacamole server must be able to reach the remote computer
   - Test connectivity: `ping <remote-ip-address>` from the Guacamole server
   - Firewall must allow connections on the RDP port (default: 3389)

3. **Authentication Credentials:**
   - Valid username and password for the remote computer
   - For domain accounts: Domain name and credentials
   - For local accounts: Local username and password

#### For VNC Connections:
1. VNC server must be installed and running on the remote computer
2. VNC password must be configured
3. Network access to VNC port (default: 5900)

#### For SSH Connections:
1. SSH server must be running on the remote computer
2. SSH access credentials (username/password or SSH key)
3. Network access to SSH port (default: 22)

### Adding an RDP Connection

RDP (Remote Desktop Protocol) allows you to access Windows or Linux remote desktops through your browser. Guacamole acts as a gateway, so you don't need an RDP client installed.

#### Step-by-Step Guide:

**Step 1: Access Guacamole Settings**
1. Log in to Guacamole at `http://localhost:8443/guacamole`
2. Click the **Settings** icon (⚙️) in the top-right corner, or click your username → **Settings**

**Step 2: Navigate to Connections**
1. In the left sidebar, click **Connections**
2. You'll see a list of existing connections (if any)

**Step 3: Create a New Connection**
1. Click **New Connection** button (usually in the top-right or within the connections list)
2. The connection editor will open

**Step 4: Fill in Basic Connection Details**

In the **General** tab:
- **Name**: Enter a friendly name (e.g., "My Windows PC", "Production Server")
- **Parent Connection Group**: Leave as "ROOT" (or select a group if you've created one)
- **Protocol**: Select **"RDP"** from the dropdown menu

**Step 5: Configure Network Settings**

In the **Network** section:
- **Network Address**: Enter the IP address or hostname of the remote computer
  - Examples: `192.168.1.100`, `server.example.com`, `10.0.0.50`
- **Port**: Enter `3389` (default RDP port) or your custom RDP port

**Step 6: Configure Authentication**

In the **Authentication** section:
- **Username**: Enter the remote computer username
  - Examples: `Administrator`, `john.doe`, `DOMAIN\username` (for domain accounts)
- **Password**: Enter the password (optional - leave blank to be prompted each time)
- **Domain**: If using a Windows domain, enter the domain name (e.g., `MYDOMAIN`)

**Step 7: Configure Display Settings (Optional)**

In the **Display** section:
- **Color Depth**: Choose 8-bit, 16-bit, 24-bit, or 32-bit (24-bit or 32-bit recommended)
- **Width**: Screen width in pixels (e.g., `1920`)
- **Height**: Screen height in pixels (e.g., `1080`)
- **DPI**: Dots per inch (e.g., `96`)

**Step 8: Additional Settings (Optional)**

- **Security**: Choose security mode (RDP, Negotiate, TLS, etc.)
- **Enable Audio**: Check if you want audio redirection
- **Enable Printing**: Check if you want printer redirection
- **Enable Drive**: Check if you want drive redirection (for file transfer)

**Step 9: Save the Connection**
1. Click **Save** button (usually at the bottom-right)
2. The connection will now appear in your connections list

#### Using the Connection

**Method 1: From Home Screen**
1. After logging in, you'll see your connections on the home screen
2. Simply click on the connection name
3. If password wasn't saved, enter it when prompted
4. The remote desktop will open in your browser

**Method 2: From Connections List**
1. Go to **Settings** → **Connections**
2. Click on the connection name or the play icon (▶️)
3. The remote desktop will open

#### Example: Complete RDP Connection Setup

Here's a complete example for connecting to a Windows 10 computer:

```
Name: Windows 10 Desktop
Protocol: RDP
Network Address: 192.168.1.100
Port: 3389
Username: Administrator
Password: [your password]
Domain: [leave blank if not using domain]
Color Depth: 32-bit
Width: 1920
Height: 1080
Security: Negotiate
Enable Audio: ✓ (checked)
Enable Printing: ✓ (checked)
```

#### RDP Connection Troubleshooting

**Connection fails immediately:**
- Verify the remote computer is powered on and accessible:
  ```bash
  ping 192.168.1.100
  ```
- Check if Remote Desktop is enabled on the remote computer
- Verify firewall rules allow port 3389
- Confirm the IP address or hostname is correct

**"Cannot connect to guacd" error:**
- Check if guacd container is running:
  ```bash
  docker compose ps guacd
  ```
- Check guacd logs:
  ```bash
  docker compose logs guacd
  ```

**"Authentication failed" error:**
- Verify username and password are correct
- Check if the account is locked or disabled
- For domain accounts, ensure you include the domain: `DOMAIN\username`

**Connection is slow or laggy:**
- Reduce color depth (e.g., 16-bit instead of 32-bit)
- Lower the resolution
- Check network latency between Guacamole server and remote computer
- Disable audio/video redirection if not needed

**Screen is blank or black:**
- Ensure the remote computer is logged in (not at lock screen)
- Try a different color depth setting
- Verify the remote desktop service is running

#### RDP Security Best Practices

1. **Use Strong Passwords**: Always use complex passwords for remote accounts
2. **Enable Network Level Authentication (NLA)**: If supported by the remote computer
3. **Use TLS Security Mode**: When possible, use TLS for encrypted connections
4. **Restrict Access**: Assign connections only to authorized users in Guacamole
5. **Use VPN**: For remote access, use VPN instead of exposing RDP directly to the internet
6. **Regular Updates**: Keep both Guacamole and remote systems updated

### Adding a VNC Connection

VNC (Virtual Network Computing) allows you to access remote desktops, typically on Linux or macOS systems.

#### Step-by-Step Guide:

**Step 1-3:** Follow the same steps as RDP (Access Settings → Connections → New Connection)

**Step 4: Configure Connection Details**
- **Name**: Enter a friendly name (e.g., "Linux Desktop", "Mac Mini")
- **Protocol**: Select **"VNC"** from the dropdown

**Step 5: Network Configuration**
- **Network Address**: Enter the IP address or hostname of the VNC server
- **Port**: Enter `5900` (default VNC port) or your custom port
  - Note: Some VNC servers use port 5901, 5902, etc. for multiple displays

**Step 6: Authentication**
- **Password**: Enter the VNC password configured on the remote computer
- **Username**: Usually not required for VNC (leave blank unless your VNC server requires it)

**Step 7: Display Settings (Optional)**
- **Color Depth**: Choose appropriate color depth
- **Width/Height**: Set desired resolution

**Step 8: Save**
- Click **Save** to create the connection

#### VNC Connection Troubleshooting

**Connection refused:**
- Verify VNC server is running: `systemctl status vncserver` (Linux)
- Check if VNC is listening on the correct port: `netstat -tuln | grep 5900`
- Verify firewall allows VNC port

**Authentication failed:**
- Confirm the VNC password is correct
- Check if VNC server requires username authentication
- Verify VNC server configuration

**Screen not displaying:**
- Ensure a desktop session is active on the remote computer
- Check if VNC server is configured for the correct display

### Adding an SSH Connection

SSH (Secure Shell) allows you to access remote command-line terminals through your browser.

#### Step-by-Step Guide:

**Step 1-3:** Follow the same steps as RDP (Access Settings → Connections → New Connection)

**Step 4: Configure Connection Details**
- **Name**: Enter a friendly name (e.g., "Web Server", "Database Server")
- **Protocol**: Select **"SSH"** from the dropdown

**Step 5: Network Configuration**
- **Network Address**: Enter the IP address or hostname of the SSH server
- **Port**: Enter `22` (default SSH port) or your custom SSH port

**Step 6: Authentication**

You can use either password or SSH key authentication:

**Option A: Password Authentication**
- **Username**: Enter the SSH username (e.g., `root`, `ubuntu`, `admin`)
- **Password**: Enter the password (or leave blank to be prompted)

**Option B: SSH Key Authentication (Recommended)**
- **Username**: Enter the SSH username
- **Private Key**: Paste your SSH private key content
  - Usually found in `~/.ssh/id_rsa` or `~/.ssh/id_ed25519`
  - Copy the entire key including `-----BEGIN` and `-----END` lines
- **Passphrase**: If your private key is encrypted, enter the passphrase

**Step 7: Terminal Settings (Optional)**
- **Terminal Type**: Choose terminal type (usually `xterm-256color`)
- **Color Scheme**: Select color scheme for the terminal
- **Font Name/Size**: Configure terminal font

**Step 8: Save**
- Click **Save** to create the connection

#### SSH Connection Troubleshooting

**Connection timeout:**
- Verify SSH server is running: `systemctl status ssh` or `systemctl status sshd`
- Check if SSH port is open: `netstat -tuln | grep 22`
- Verify firewall allows SSH connections
- Test SSH connectivity: `ssh username@hostname` from command line

**Authentication failed:**
- Verify username and password are correct
- For key authentication, ensure the public key is in `~/.ssh/authorized_keys` on the server
- Check key permissions (should be 600 for private key)
- Verify the private key format is correct (PEM format)

**Host key verification:**
- First connection may require accepting the host key
- If issues persist, check SSH server logs: `/var/log/auth.log` (Linux)

#### SSH Security Best Practices

1. **Use SSH Keys**: Prefer SSH key authentication over passwords
2. **Disable Root Login**: Configure SSH server to disallow root login
3. **Change Default Port**: Use a non-standard SSH port (not 22) for additional security
4. **Use Strong Keys**: Use ED25519 or RSA 4096-bit keys
5. **Regular Key Rotation**: Periodically rotate SSH keys

### General Connection Troubleshooting

If you're experiencing issues with any type of connection, check the following:

#### Verify Guacamole Services

1. **Check all containers are running:**
   ```bash
   docker compose ps
   ```
   All services (postgres, guacd, guacamole) should show "Up"

2. **Check Guacamole logs:**
   ```bash
   docker compose logs guacamole --tail=50
   ```

3. **Check guacd logs:**
   ```bash
   docker compose logs guacd --tail=50
   ```

#### Network Connectivity Issues

1. **Test network connectivity from Guacamole server:**
   ```bash
   # Test if remote host is reachable
   docker compose exec guacamole ping <remote-ip>
   
   # Test if port is open
   docker compose exec guacamole nc -zv <remote-ip> <port>
   ```

2. **Verify firewall rules:**
   - Ensure the remote computer's firewall allows connections
   - Check if Guacamole server can reach the remote computer
   - Verify port forwarding if using NAT

#### Connection Performance Issues

1. **Reduce connection quality:**
   - Lower color depth
   - Reduce resolution
   - Disable audio/video redirection

2. **Check network latency:**
   ```bash
   docker compose exec guacamole ping <remote-ip>
   ```

3. **Monitor resource usage:**
   ```bash
   docker stats
   ```

#### Common Error Messages

- **"Connection refused"**: Remote service is not running or port is blocked
- **"Authentication failed"**: Incorrect credentials or account issues
- **"Cannot connect to guacd"**: guacd service is not running or unreachable
- **"Connection timeout"**: Network connectivity issue or firewall blocking
- **"Screen is blank"**: Display/desktop session issue on remote computer

## Managing the Docker Instance

### Starting the Services

To start all Guacamole services:

```bash
docker compose up -d
```

The `-d` flag runs containers in detached mode (in the background).

### Stopping the Services

To stop all running containers without removing them:

```bash
docker compose stop
```

This will stop all containers but preserve their state. You can restart them later with `docker compose start`.

### Stopping and Removing Containers

To stop and remove all containers (but keep volumes and data):

```bash
docker compose down
```

This stops and removes containers, networks, but **preserves volumes** (your database data will remain).

### Completely Removing Everything (Including Data)

⚠️ **Warning:** This will delete all data including the database!

To stop containers, remove them, and delete all volumes (including database data):

```bash
docker compose down -v
```

Or to remove everything including images:

```bash
docker compose down -v --rmi all
```

### Restarting Services

To restart all services:

```bash
docker compose restart
```

To restart a specific service:

```bash
docker compose restart guacamole
docker compose restart guacd
docker compose restart postgres
```

### Viewing Container Status

To check which containers are running:

```bash
docker compose ps
```

To see detailed status of all services:

```bash
docker compose ps -a
```

### Viewing Logs

To view logs from all services:

```bash
docker compose logs
```

To follow logs in real-time:

```bash
docker compose logs -f
```

To view logs from a specific service:

```bash
docker compose logs guacamole
docker compose logs guacd
docker compose logs postgres
```

To view the last N lines of logs:

```bash
docker compose logs --tail=50 guacamole
```

### Quick Reference Commands

| Action | Command |
|--------|---------|
| Start services | `docker compose up -d` |
| Stop services (keep containers) | `docker compose stop` |
| Start stopped services | `docker compose start` |
| Stop and remove containers | `docker compose down` |
| Stop and remove everything (including data) | `docker compose down -v` |
| Restart all services | `docker compose restart` |
| Restart specific service | `docker compose restart <service-name>` |
| View container status | `docker compose ps` |
| View logs | `docker compose logs` |
| Follow logs | `docker compose logs -f` |
| View specific service logs | `docker compose logs <service-name>` |

## Troubleshooting

### Issue: Cannot access Guacamole web interface

**Solutions:**
1. Check if containers are running:
   ```bash
   docker compose ps
   ```

2. Check Guacamole logs for errors:
   ```bash
   docker compose logs guacamole
   ```

3. Verify port 8443 is not in use:
   ```bash
   lsof -i :8443  # macOS/Linux
   netstat -ano | findstr :8443  # Windows
   ```

4. Check if the database was initialized:
   ```bash
   docker compose exec postgres psql -U guacamole_user -d guacamole_db -c "\dt"
   ```

### Issue: Database connection errors

**Symptoms:** Logs show "Cannot connect to database" or similar errors

**Solutions:**
1. Verify PostgreSQL is running:
   ```bash
   docker compose logs postgres
   ```

2. Check database credentials in `docker-compose.yml` match what's configured

3. Ensure database schema was initialized (see [Database Initialization](#database-initialization))

4. Test database connection:
   ```bash
   docker compose exec postgres psql -U guacamole_user -d guacamole_db -c "SELECT version();"
   ```

### Issue: guacd connection errors

**Symptoms:** Connections fail with "Cannot connect to guacd"

**Solutions:**
1. Verify guacd container is running:
   ```bash
   docker compose logs guacd
   ```

2. Check network connectivity:
   ```bash
   docker compose exec guacamole ping guacd
   ```

3. Verify `GUACD_HOSTNAME` environment variable is set to `guacd` in docker-compose.yml

### Issue: Login page shows but cannot log in

**Solutions:**
1. Verify the admin user was created:
   ```bash
   docker compose exec postgres psql -U guacamole_user -d guacamole_db -c "SELECT * FROM guacamole_user;"
   ```

2. If no users exist, run the admin user creation script:
   ```bash
   docker compose exec -T postgres psql -U guacamole_user -d guacamole_db < db-init/002-create-admin-user.sql
   ```

3. Try resetting the admin password manually (see database reset section)

### Issue: Remote connections fail

**Solutions:**
1. Verify the remote server is accessible from the Docker host:
   ```bash
   ping REMOTE_SERVER_IP
   telnet REMOTE_SERVER_IP PORT
   ```

2. Check firewall rules on the remote server

3. Verify connection settings in Guacamole (correct IP, port, credentials)

4. Check guacd logs:
   ```bash
   docker compose logs guacd
   ```

### Resetting the Database

If you need to start fresh:

```bash
# Stop all services
docker compose down

# Remove the database volume (WARNING: This deletes all data!)
docker volume rm apache_guacamole_postgres_data

# Start PostgreSQL and reinitialize
docker compose up -d postgres
# Wait for it to be ready, then run initialization scripts again
```

## Configuration Options

### Changing the Port

To change the port Guacamole is accessible on, edit `docker-compose.yml`:

```yaml
guacamole:
  ports:
    - "YOUR_PORT:8080"  # Change YOUR_PORT to desired port
```

Then restart:
```bash
docker compose up -d
```

### Changing Database Credentials

1. Edit `docker-compose.yml` and update:
   - `POSTGRES_DB`
   - `POSTGRES_USER`
   - `POSTGRES_PASSWORD`
   - Corresponding values in the `guacamole` service environment

2. If the database already exists, you'll need to recreate it:
   ```bash
   docker compose down -v
   docker compose up -d postgres
   # Reinitialize database with new credentials
   ```

### Enabling Debug Logging

To enable debug logging for guacd, edit `docker-compose.yml`:

```yaml
guacd:
  environment:
    LOG_LEVEL: debug
```

### Persistent Data

Database data is automatically persisted in a Docker volume named `postgres_data`. To backup:

```bash
# Backup
docker compose exec postgres pg_dump -U guacamole_user guacamole_db > backup.sql

# Restore
docker compose exec -T postgres psql -U guacamole_user -d guacamole_db < backup.sql
```

## Additional Resources

- **Official Documentation**: https://guacamole.apache.org/doc/gug/
- **Docker Documentation**: https://guacamole.apache.org/doc/gug/guacamole-docker.html
- **GitHub Repository**: https://github.com/apache/guacamole-client
- **Community Support**: https://guacamole.apache.org/support/

## Security Notes

⚠️ **Important Security Considerations:**

1. **Change default credentials immediately** after first login
2. **Use strong passwords** for the database and Guacamole users
3. **Consider using environment files** (`.env`) for sensitive credentials instead of hardcoding in `docker-compose.yml`
4. **Enable SSL/TLS** if accessing over the internet (requires reverse proxy configuration)
5. **Restrict network access** to the Guacamole port (8443) using firewall rules
6. **Keep Docker images updated** regularly:
   ```bash
   docker compose pull
   docker compose up -d
   ```

## Support

If you encounter issues not covered in this guide:

1. Check the [official Guacamole documentation](https://guacamole.apache.org/doc/gug/)
2. Review Docker logs: `docker compose logs`
3. Check the [Guacamole mailing lists](https://guacamole.apache.org/support/) for community support

---

**Last Updated**: Based on Apache Guacamole documentation v1.6.0


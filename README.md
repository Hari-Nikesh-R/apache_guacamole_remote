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

After logging in, you can add remote desktop connections:

### Adding an RDP Connection

1. Click **Settings** (gear icon) in the top menu
2. Click **Connections** in the left sidebar
3. Click **New Connection**
4. Fill in the connection details:
   - **Name**: A friendly name for the connection
   - **Protocol**: Select "RDP"
   - **Network**: Enter the hostname or IP address
   - **Port**: 3389 (default RDP port)
   - **Username**: Remote desktop username
   - **Password**: Remote desktop password (or leave blank to prompt)
5. Click **Save**

### Adding a VNC Connection

1. Follow steps 1-3 above
2. Set **Protocol** to "VNC"
3. Enter connection details:
   - **Network**: VNC server address
   - **Port**: 5900 (default VNC port)
   - **Password**: VNC password
4. Click **Save**

### Adding an SSH Connection

1. Follow steps 1-3 above
2. Set **Protocol** to "SSH"
3. Enter connection details:
   - **Network**: SSH server address
   - **Port**: 22 (default SSH port)
   - **Username**: SSH username
   - **Private Key**: Paste your SSH private key (optional)
4. Click **Save**

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


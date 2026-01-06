-- ============================================================================
-- Apache Guacamole Database Initialization Helper Script
-- ============================================================================
-- 
-- IMPORTANT: This file is a reference/helper script. The actual SQL scripts
-- must be downloaded from the official Apache Guacamole repository.
--
-- This script provides instructions and a template for database initialization.
-- You need to download the actual schema files from:
-- https://github.com/apache/guacamole-client/tree/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema
--
-- ============================================================================

-- ============================================================================
-- STEP 1: Download Required SQL Scripts
-- ============================================================================
-- 
-- You need to download these files from the Guacamole repository:
--
-- 1. 001-create-schema.sql
--    URL: https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/001-create-schema.sql
--
-- 2. 002-create-admin-user.sql (optional, creates default admin user)
--    URL: https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/002-create-admin-user.sql
--
-- Download commands (run from project root):
--   mkdir -p db-init
--   curl -L https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/001-create-schema.sql -o db-init/001-create-schema.sql
--   curl -L https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/002-create-admin-user.sql -o db-init/002-create-admin-user.sql
--
-- ============================================================================

-- ============================================================================
-- STEP 2: Execute the Schema Scripts
-- ============================================================================
--
-- Once downloaded, execute them in order:
--
-- Method 1: Using docker compose exec
--   docker compose exec -T postgres psql -U guacamole_user -d guacamole_db < db-init/001-create-schema.sql
--   docker compose exec -T postgres psql -U guacamole_user -d guacamole_db < db-init/002-create-admin-user.sql
--
-- Method 2: Copy files into container and execute
--   docker cp db-init/001-create-schema.sql guacamole-postgres:/tmp/
--   docker compose exec postgres psql -U guacamole_user -d guacamole_db -f /tmp/001-create-schema.sql
--   docker cp db-init/002-create-admin-user.sql guacamole-postgres:/tmp/
--   docker compose exec postgres psql -U guacamole_user -d guacamole_db -f /tmp/002-create-admin-user.sql
--
-- ============================================================================

-- ============================================================================
-- STEP 3: Verify Database Initialization
-- ============================================================================
--
-- After running the scripts, verify the schema was created:
--
--   docker compose exec postgres psql -U guacamole_user -d guacamole_db -c "\dt"
--
-- You should see tables like:
--   - guacamole_user
--   - guacamole_connection
--   - guacamole_connection_group
--   - guacamole_connection_parameter
--   - etc.
--
-- Verify the admin user was created:
--
--   docker compose exec postgres psql -U guacamole_user -d guacamole_db -c "SELECT * FROM guacamole_user;"
--
-- You should see a user with username 'guacadmin'
--
-- ============================================================================

-- ============================================================================
-- MANUAL ADMIN USER CREATION (Alternative)
-- ============================================================================
-- 
-- If you prefer to create the admin user manually instead of using the
-- 002-create-admin-user.sql script, you can use the following SQL commands.
-- 
-- Note: The password is MD5 hashed. The default password 'guacadmin' hashes to:
-- 'baac0d060df51a546b0c9e6e79f4c902'
--
-- To create a custom password hash, you can use:
--   echo -n 'YOUR_PASSWORD' | md5sum
--   (then prepend the username and a colon, then hash again)
--
-- Or use PostgreSQL's crypt function if pgcrypto extension is enabled.
--
-- ============================================================================

-- Create the default administrator user (guacadmin/guacadmin)
-- This is equivalent to what 002-create-admin-user.sql does

-- First, ensure the guacamole_user table exists (from 001-create-schema.sql)
-- Then insert the admin user with MD5 hashed password

-- The password hash for 'guacadmin' is calculated as:
-- MD5('guacadmin:guacadmin:baac0d060df51a546b0c9e6e79f4c902')
-- Where 'baac0d060df51a546b0c9e6e79f4c902' is MD5('guacadmin')

INSERT INTO guacamole_user (username, password_hash, password_salt, disabled)
VALUES (
    'guacadmin',
    'baac0d060df51a546b0c9e6e79f4c902',  -- MD5 hash of 'guacadmin'
    NULL,
    FALSE
)
ON CONFLICT (username) DO NOTHING;

-- Grant the admin user system-level permissions
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, 'ADMINISTER'
FROM guacamole_entity
WHERE name = 'guacadmin' AND type = 'USER'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- NOTES
-- ============================================================================
--
-- 1. The actual schema creation script (001-create-schema.sql) is quite large
--    and creates all necessary tables, indexes, and constraints. It should
--    always be run first.
--
-- 2. The admin user creation script (002-create-admin-user.sql) is optional
--    but recommended for initial setup. It creates the default 'guacadmin' user.
--
-- 3. After first login, you MUST change the default password for security.
--
-- 4. For production deployments, consider:
--    - Using stronger passwords
--    - Setting up LDAP/Active Directory authentication
--    - Enabling SSL/TLS
--    - Implementing proper backup strategies
--
-- 5. Database credentials are defined in docker-compose.yml:
--    - Database: guacamole_db
--    - User: guacamole_user
--    - Password: guacamole_password
--    (Change these for production!)
--
-- ============================================================================

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================
--
-- If you encounter errors:
--
-- 1. Ensure PostgreSQL container is running:
--    docker compose ps postgres
--
-- 2. Check PostgreSQL logs:
--    docker compose logs postgres
--
-- 3. Verify database exists:
--    docker compose exec postgres psql -U guacamole_user -l
--
-- 4. Check if schema already exists:
--    docker compose exec postgres psql -U guacamole_user -d guacamole_db -c "\dt"
--    (If tables exist, schema was already initialized)
--
-- 5. To start fresh, remove the volume and recreate:
--    docker compose down -v
--    docker compose up -d postgres
--    (Then re-run initialization scripts)
--
-- ============================================================================


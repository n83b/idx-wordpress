#!/bin/bash
#!/bin/bash

# Set MySQL root credentials
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASSWORD="" # Leave empty if no password

# Set variables
DB_HOST="127.0.0.1"
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASSWORD="wppassword"
SITE_URL="http://localhost:3000"
SITE_TITLE="My WordPress Site"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"
ADMIN_EMAIL="admin@example.com"


# Check if the database exists
DB_EXISTS=$(mysql -u $MYSQL_ROOT_USER -Nse "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$DB_NAME';")

if [ -z "$DB_EXISTS" ]; then
    echo "📌 Database '$DB_NAME' does not exist. Creating it now..."
    mysql -u $MYSQL_ROOT_USER -e "CREATE DATABASE $DB_NAME;"
    echo "✅ Database '$DB_NAME' created."
else
    echo "⚠️ Database '$DB_NAME' already exists. Skipping creation."
fi

# Check if the MySQL user exists
USER_EXISTS=$(mysql -u $MYSQL_ROOT_USER -Nse "SELECT User FROM mysql.user WHERE User='$DB_USER';")

if [ -z "$USER_EXISTS" ]; then
    echo "📌 User '$DB_USER' does not exist. Creating it now..."
    mysql -u $MYSQL_ROOT_USER -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
    echo "✅ User '$DB_USER' created."
else
    echo "⚠️ User '$DB_USER' already exists. Skipping creation."
fi

# Check if the user has privileges on the database
PRIV_EXISTS=$(mysql -u $MYSQL_ROOT_USER -Nse "SELECT COUNT(*) FROM information_schema.schema_privileges WHERE grantee = '''$DB_USER''@''localhost''' AND table_schema = '$DB_NAME';")

if [ "$PRIV_EXISTS" -eq 0 ]; then
    echo "📌 Granting privileges to '$DB_USER' on database '$DB_NAME'..."
    mysql -u $MYSQL_ROOT_USER -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    mysql -u $MYSQL_ROOT_USER -e "FLUSH PRIVILEGES;"
    echo "✅ Privileges granted."
else
    echo "⚠️ User '$DB_USER' already has access to '$DB_NAME'. Skipping privilege grant."
fi

echo "✅ MySQL setup complete!"


# Check if WordPress is already installed
if wp core is-installed --allow-root; then
    echo "✅ WordPress is already installed. Skipping installation."
    exit 0
else
    echo "❌ WordPress is not installed. Proceeding with installation..."
fi

# Download WordPress
echo "📥 Downloading WordPress..."
wp core download --allow-root

# Configure wp-config.php if it doesn't exist
if [ ! -f wp-config.php ]; then
    echo "🔧 Configuring WordPress..."
    wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASSWORD --dbhost=$DB_HOST --allow-root
fi

# Install WordPress
echo "🚀 Installing WordPress..."
wp core install --url="$SITE_URL" --title="$SITE_TITLE" --admin_user="$ADMIN_USER" --admin_password="$ADMIN_PASSWORD" --admin_email="$ADMIN_EMAIL" --allow-root

echo "✅ WordPress installation complete!"
echo "🔗 Admin URL: $SITE_URL/wp-admin"
echo "👤 Username: $ADMIN_USER"
echo "🔑 Password: $ADMIN_PASSWORD"

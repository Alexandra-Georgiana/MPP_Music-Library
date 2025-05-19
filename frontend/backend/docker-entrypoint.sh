#!/bin/bash
# Script to set up locale in Railway container

# Install required packages
apt-get update
apt-get install -y locales

# Generate the locale
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Set the locale environment variables
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

echo "Locale setup complete"
echo "Current locale settings:"
locale

# Continue with your application
exec "$@"

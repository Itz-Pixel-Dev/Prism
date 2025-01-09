#!/bin/bash

# Function to display messages
function display_message {
    echo -e "\n\033[1;34m$1\033[0m"
}

# Function to show a spinner
function show_spinner {
    local pid=$1
    local delay=0.75
    local spin='/-\|'
    local i=0
    while ps -p $pid > /dev/null; do
        local temp=${spin:i++%${#spin}:1}
        echo -ne "\b$temp"
        sleep $delay
    done
    echo -ne "\b"
}

# Placeholder for graphic
echo -e "\033[1;32m"
echo "Displaying graphic: [Insert graphic with text 'Prism' here]"
echo -e "\033[0m"

# Check for prerequisites
display_message "Checking for prerequisites..."

# Check for Bun
if ! command -v bun &> /dev/null; then
    display_message "Bun is not installed. Installing Bun v1.1.42 or higher..."
    (curl -fsSL https://bun.sh/install | bash) &
    show_spinner $!
    if ! command -v bun &> /dev/null; then
        display_message "Bun installation failed. Please install Bun manually."
        exit 1
    fi
    source ~/.bashrc
    display_message "Bun installed successfully."
else
    display_message "Bun is already installed."
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
    display_message "Node.js is not installed. Please install Node.js v18+."
    exit 1
fi

# Check for Redis
if ! command -v redis-server &> /dev/null; then
    display_message "Redis is not installed. Please install Redis."
    exit 1
fi

# Check for Nginx
if ! command -v nginx &> /dev/null; then
    display_message "Nginx is not installed. Please install Nginx."
    exit 1
fi

# Edit Wings configuration
display_message "Please edit your Wings configuration file at /etc/pterodactyl/config.yml."
display_message "Change 'allowed-origins: []' to either 'allowed-origins: [*]' or 'allowed-origins: [https://your-dashboard-domain.com]'."

# Install Redis
display_message "Installing Redis..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -f /etc/debian_version ]]; then
        sudo apt update
        (sudo apt install redis-server -y) &
        show_spinner $!
        if ! command -v redis-server &> /dev/null; then
            display_message "Redis installation failed. Please install Redis manually."
            exit 1
        fi
    elif [[ -f /etc/redhat-release ]]; then
        sudo dnf install epel-release -y
        (sudo dnf install redis -y) &
        show_spinner $!
        if ! command -v redis-server &> /dev/null; then
            display_message "Redis installation failed. Please install Redis manually."
            exit 1
        fi
    fi
    sudo systemctl start redis
    sudo systemctl enable redis
else
    display_message "Unsupported OS. Please install Redis manually."
    exit 1
fi

# Upgrade to Bun Canary
display_message "Upgrading to Bun Canary..."
(bun upgrade --canary) &
show_spinner $!

# Clone the repository
display_message "Cloning the Prism repository..."
(git clone https://github.com/PrismFOSS/Prism) &
show_spinner $!
if [ $? -ne 0 ]; then
    display_message "Failed to clone the repository. Please check your internet connection or the repository URL."
    exit 1
fi
cd Prism || exit

# Install dependencies
display_message "Installing dependencies..."
(bun install) &
show_spinner $!
if [ $? -ne 0 ]; then
    display_message "Failed to install dependencies. Please check the Bun installation."
    exit 1
fi

# Create configuration file
display_message "Creating configuration file..."
cp example_config.toml config.toml

# Instructions for configuring config.toml
display_message "Please configure your config.toml file as needed."

# Build and start Prism
display_message "Building and starting Prism..."
cd app || exit
(npm install) &
show_spinner $!
if [ $? -ne 0 ]; then
    display_message "Failed to install npm dependencies. Please check your Node.js installation."
    exit 1
fi
(npm run build) &
show_spinner $!
cd ../
(bun run app.js) &

# Nginx configuration
display_message "Please configure Nginx with the provided configuration in the README."

display_message "Installation completed successfully!"

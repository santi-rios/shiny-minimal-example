# shiny-minimal-example



### 1. Prepare Your Shiny Application
- Package your app in a directory with:
  - `app.R` (or `ui.R` + `server.R`)
  - Any required data/files
  - `requirements.R` (list of required packages)

### 2. Transfer Files to Server
```bash
# From your local machine
scp -r your_app_directory bermudez@hydra:/path/to/destination
```

### 3. Install Required R Packages
Connect to the server and install dependencies:
```R
# In R console
  # Checar paquetes necesarios
  list.of.packages <- c("echarts4r", "magrittr", "shiny")
  # Comparar output para instalar paquetes
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
  if(length(new.packages)) install.packages(new.packages)
```

### 4. Install Shiny Server
```bash
# Install required dependencies
sudo apt-get install gdebi-core

# Download and install Shiny Server
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
sudo gdebi shiny-server-1.5.22.1017-amd64.deb
```

### 4. Install Shiny Server B

Shiny Server (open source) will serve your Shiny apps on a dedicated port (by default, 3838).

    Download the .deb Package:
    Visit the Shiny Server download page from your local browser to get the latest URL for the Debian package. Then, on your server, run:

wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.20.1002-amd64.deb

(Note: The URL may change; please verify the latest version for Debian.)

Install the Package:
Install required helper tools and the package:

sudo apt-get update
sudo apt-get install -y gdebi-core
sudo gdebi shiny-server-1.5.20.1002-amd64.deb

This installs Shiny Server and its dependencies.

Verify Installation:
Shiny Server runs as a service. Check its status with:

sudo systemctl status shiny-server

If it is running, it will be listening on port 3838.

Test Shiny Server:
From a browser (or using curl from the server), try accessing:

http://your.server.address:3838/

You should see the default Shiny Server welcome page. Your uploaded app should appear in the directory listing (typically, every subfolder in /srv/shiny-server/ is served as a separate app).




### 5. Configure Shiny Server
Edit the configuration file:
```bash
sudo nano /etc/shiny-server/shiny-server.conf
```
Add this configuration:
```conf
# Define the user to run processes as
run_as bermudez;

# Define a top-level server which will listen on a port
server {
  # Instruct to listen on port 3838
  listen 3838;

  # Define the location available at the base URL
  location / {
    # Host the directory of Shiny apps
    site_dir /srv/shiny-server;
    
    # Log all Shiny output to individual files
    log_dir /var/log/shiny-server;
    
    # Allow directory listing
    directory_index on;
  }
}
```

### 6. Deploy Your Application
```bash
# Copy your app to Shiny Server directory
sudo cp -r your_app_directory /srv/shiny-server/

# Set proper permissions
sudo chmod -R 755 /srv/shiny-server/your_app_directory
sudo chown -R bermudez:shiny /srv/shiny-server/your_app_directory
```

### 7. Configure Apache Reverse Proxy
Create a new Apache configuration file:
```bash
sudo nano /etc/apache2/sites-available/shiny.conf
```
Add this configuration:
```apache
<VirtualHost *:80>
    ServerName your-domain.com
    ServerAlias www.your-domain.com

    ProxyPreserveHost On
    ProxyRequests Off
    
    <Proxy *>
        Require all granted
    </Proxy>

    ProxyPass / http://localhost:3838/
    ProxyPassReverse / http://localhost:3838/
    
    ErrorLog ${APACHE_LOG_DIR}/shiny-error.log
    CustomLog ${APACHE_LOG_DIR}/shiny-access.log combined
</VirtualHost>
```
Enable the configuration:
```bash
sudo a2ensite shiny.conf
sudo systemctl reload apache2
```

### 8. Start Shiny Server
```bash
# Start the service
sudo systemctl start shiny-server

# Enable automatic startup
sudo systemctl enable shiny-server

# Check status
sudo systemctl status shiny-server
```

### 9. Access Your Application
Your app will be available at:
```
http://hydra/your_app_directory
```
or through the reverse proxy at:
```
http://your-domain.com/your_app_directory
```

### 10. Maintenance Commands
```bash
# Restart Shiny Server
sudo systemctl restart shiny-server

# Check logs
tail -f /var/log/shiny-server.log
```

### Important Notes:
1. Storage: Use `/pool` (5.4TB available) for large datasets
2. Ports: Apache is already configured with ports 80/443 open
3. Security: Contact admins if you need SSL/TLS configuration
4. Resources: Monitor usage with `top` or `htop`

### Troubleshooting:
1. Check Shiny Server logs: `/var/log/shiny-server/`
2. Verify Apache proxy: `sudo apache2ctl configtest`
3. Test direct access: `curl http://localhost:3838/your_app_directory`

Let me know if you need help with:
- Setting up authentication
- Configuring SSL/TLS
- Managing multiple applications
- Resource monitoring setup


4. (Optional) Integrate with Apache Using Reverse Proxy

Since your server is already running Apache (listening on port 80/443), you might want your users to access your Shiny app via the standard HTTP/HTTPS ports. This is done by proxying Apache requests to Shiny Server.
a. Enable Proxy Modules in Apache

Run the following commands to enable the necessary Apache modules:

sudo a2enmod proxy
sudo a2enmod proxy_http

Then restart Apache:

sudo systemctl restart apache2

b. Configure Apache as a Reverse Proxy

Edit (or create) an Apache configuration file (for example, /etc/apache2/sites-available/shiny.conf) with a VirtualHost or a location block. Here’s a sample configuration that proxies requests from /shiny/ to your Shiny Server (running on port 3838):

<VirtualHost *:80>
    ServerName your.server.address  # Replace with your server's hostname or IP

    # Proxy requests for /shiny/ to the Shiny Server
    ProxyPass /shiny/ http://127.0.0.1:3838/
    ProxyPassReverse /shiny/ http://127.0.0.1:3838/

    # Optionally, you can also configure SSL (if needed) and other settings.
    ErrorLog ${APACHE_LOG_DIR}/shiny_error.log
    CustomLog ${APACHE_LOG_DIR}/shiny_access.log combined
</VirtualHost>

    Enable the New Site:

    sudo a2ensite shiny.conf
    sudo systemctl reload apache2

c. Accessing Your App

Now, users can access your Shiny app by navigating to:

http://your.server.address/shiny/your_app_folder/

Here, your_app_folder is the subdirectory name under /srv/shiny-server/ that contains your Shiny app.
5. (Alternative) Running the Shiny App as a Standalone R Process

If you prefer not to install Shiny Server, you can run your Shiny app directly with R (for example, via Rscript) and manage it with a process manager (like systemd).
a. Create a Startup Script

Create a script (e.g., /home/bermudez/start_shiny_app.sh) with the following contents:

#!/bin/bash
Rscript -e "shiny::runApp('/path/to/your/app', port=3838, host='0.0.0.0')"

Make it executable:

chmod +x /home/bermudez/start_shiny_app.sh

b. Create a systemd Service File

Create a file called /etc/systemd/system/shiny_app.service with contents like:

[Unit]
Description=My Shiny App
After=network.target

[Service]
Type=simple
ExecStart=/home/bermudez/start_shiny_app.sh
User=bermudez
Restart=on-failure

[Install]
WantedBy=multi-user.target

Enable and start the service:

sudo systemctl daemon-reload
sudo systemctl enable shiny_app.service
sudo systemctl start shiny_app.service

Your Shiny app will now run in the background, and you can use the Apache reverse proxy instructions above to expose it to users.
6. Final Considerations

    Firewall/Network Settings:
    Ensure that the necessary ports (80/443 for Apache and/or 3838 for direct Shiny Server access) are open and allowed by your university’s firewall policy.

    Security:
    If you plan to expose your app publicly, consider setting up SSL (using Apache’s Let’s Encrypt integration, for example) to secure the connection.

    Logs and Troubleshooting:

        Check Apache logs in /var/log/apache2/ for any proxy-related errors.

        Shiny Server logs can be found in /var/log/shiny-server/ for issues related to app deployment.

    Updates:
    Remember to update R packages and your app code as needed. Monitor the server’s resource usage (e.g., via df -h and other system tools) to ensure smooth operation.
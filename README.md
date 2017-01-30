
# Hillebrandt Server Access Report

      Version: 1.1
      Author: Patricia Hillebrandt
      Release date: 20-11-2016
      Latest version: 30-01-2017
      License: GNU General Public License V3
      License URI: http://www.gnu.org/licenses/gpl.html

## 1- This script generates a report listing the number, Location and Organization of the IPs that are accessing:

- General pages of the website (Top 20 IPs)
- The wp-login.php file (Top 10 IPs)
- The xmlrpc.php file (Top 10 IPs)

Also, it generates a report comparing the number of requests/accesses a given website had from all PHP and NGINX access logs in the server.


## 2- Dependencies:

This script was built to work with Ubuntu web servers running Nginx with php-fpm 7.

Built to work with these log formats:

- PHP-fpm:

   access.format = "%{mega}MMb %{mili}dms pid=%p %C%% %R - %u %t \"%m %r%Q%q\" %s %f"

- NGINX log format:

   log_format vhost '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $body_bytes_sent '
        '"$http_referer" "$http_user_agent" "$proxy_add_x_forwarded_for"' ;

## 3- How to install:

- Place this script (hillebrandt-access-report.sh) inside the directory /usr/local/bin/

- Run the following command to activate/allow to execute the script: chmod +x hillebrandt-access-report.sh

- Now you can type hillebrandt-access-report.sh in your terminal and analize the IP addresses that are accessing your site!
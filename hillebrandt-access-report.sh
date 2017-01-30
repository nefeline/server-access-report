#!/bin/bash
# ------------------------------------------------------------------
#          Title: Hillebrandt Server Access Report
#          Version: 1.1
#          Author: Patricia Hillebrandt
#          Release date: 20-11-2016
#          Latest version: 30-01-2017
#          License: GNU General Public License V3 or later
#          License URI: http://www.gnu.org/licenses/gpl.html
#          Description: This script generates a report listing the
#          Number, Location and Organization of the IPs that are
#          accessing:
#
#          - General pages of the website (Top 20 IPs)
#          - The wp-login.php file (Top 10 IPs)
#          - The xmlrpc.php file (Top 10 IPs)
#
#          Also, it generates a report comparing the number of
#          requests/accesses a given website had from all PHP and
#          NGINX access logs in the server.
#
#  Dependency: This script connects to IP Geolocation API to obtain
#              further info about the IP addresses:
#              http://ip-api.com/
#
#              Built to work with these log formats:
#
#            * NGINX log format:
#
#               log_format vhost '$remote_addr - $remote_user [$time_local] '
#                    '"$request" $status $body_bytes_sent '
#                    '"$http_referer" "$http_user_agent" "$proxy_add_x_forwarded_for"' ;
# ------------------------------------------------------------------

validation() {
    if [[ "$(id -u)" != "0" ]]; then
        echo "root privileges are required to run this script."
        exit 1
    fi
}

choose_site() {
    echo "------------------------------------------------------------------------"
    printf "Type the number of the site you want to verify (press Ctrl-C to cancel):\n"
    echo "------------------------------------------------------------------------"
    cd /var/www/
    listsites=`ls -1`
    select site in ${listsites[@]}; do
        test -n "$site" && break;
        echo ">>> Invalid Selection";
    done
    echo "==========================================="
    echo "You selected: $site"
    echo "==========================================="
}

#Table Format
divider=================================================
divider=$divider$divider

table_format_compare_accesses() {
    width=40
    header="\n %-10s %8s %10s\n"
    printf "$header" "Date" "NGINX" "PHP"
    printf "%$width.${width}s\n" "$divider"
}

table_format_top_ip() {
    width=87
    header="\n %-5s %40s %18s %20s\n"
    printf "$header" "Nº" "IP Address" "Country" "Organization"
    printf "%$width.${width}s\n" "$divider"
}

#Connects to ip-api to obtain general info about IPs accessing the server.
api_call() {
    ip=`echo $line | awk '{ print $2 }'`
    count=`echo $line | awk '{ print $1 }'`
    api_output=`curl -s http://ip-api.com/json/$ip`

    format=" %-5s %40s %18s %20s\n"
    location=$(echo $api_output | grep -Po '"country":.*?[^\\]"'| sed 's/"//g' | awk '{gsub("country:", "");print}')
    organization=$(echo $api_output | grep -Po '"org":.*?[^\\]"'| sed 's/"//g' | awk '{gsub("org:", "");print}')

    printf "$format" \
    $count $ip "$location" "$organization"
}

# Shows the number of client requests in NGINX and PHP-fpm access logs.
synthesis_compare_accesses_number() {
    format=" %-10s %8s %10s\n"
    echo " "
    echo "-----------------------------------------"
    printf "Number of accesses in $build_type and PHP logs:\n"
    table_format_compare_accesses
    for nginx_log in `ls -tlah /var/log/nginx/$site.access.log* | cut -d/ -f5`; do
        nginx_accesses=`zcat -f /var/log/nginx/$nginx_log | wc -l | cut -d " " -f1`
        date=`date -r /var/log/nginx/$nginx_log | awk {'print $3"/"$2"/"$6'}`

        php_accesses=0
        for php_log in `ls -tlah /var/log/php7.0-fpm.$site.access.log* | cut -d/ -f4`; do
            php_accesses=$(( `zcat -f /var/log/$php_log | grep "$date" | grep "$site" | wc -l | cut -d " " -f1` + $php_accesses ))
        done

        printf "$format" \
        "$date" "$nginx_accesses" "$php_accesses"
    done
}

# Shows the top 20 IP addresses accessing the website and location info.
synthesis_topips_accesses() {
    echo " "
    echo "---------------------------------------------------------------------------------------"
    printf "Top 20 IP address accessing the website:\n"
    table_format_top_ip
    grep -Po '\"\S*?(\,\s)?\S*\"$' /var/log/nginx/$site.access.log | sort | uniq -c | sort -nr | head -n 20 | sed 's/"//g' | sed 's/,/ /g' | while read line; do
        api_call
    done
}

# Shows the top 10 IPs accessing wp-login.php and xmlrpc.php and location info.
synthesis_topips_accessing_wplogin() {
    echo " "
    echo "---------------------------------------------------------------------------------------"
    printf "Top 10 IP addresses accessing wp-login.php:\n"
    table_format_top_ip
    egrep "wp-login.php" /var/log/nginx/$site.access.log | grep -Po '\"\S*?(\,\s)?\S*\"$' | sort | uniq -c | sort -nr | head -n 10 | sed 's/"//g' | sed 's/,/ /g' | while read line; do
        api_call
    done

    echo " "
    echo "---------------------------------------------------------------------------------------"
    printf "Top 10 IP addresses accessing xmlrpc.php:\n"
    table_format_top_ip
        egrep "xmlrpc.php" /var/log/nginx/$site.access.log | grep -Po '\"\S*?(\,\s)?\S*\"$' | sort | uniq -c | sort -nr | head -n 10 | sed 's/"//g' | sed 's/,/ /g' | while read line; do
            api_call
        done
}

validation
nginx_apache_validation
choose_site
synthesis_compare_accesses_number
synthesis_topips_accesses
synthesis_topips_accessing_wplogin

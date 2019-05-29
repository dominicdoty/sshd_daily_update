# sshd_daily_update
A simple script that parses the auth &amp; fail2ban logs for emailing to an admin every morning.

It provides analysis of the previous day's traffic, with output like this:

```
Analyzing logs from May 28 00:00:01 to May 28 23:59:59

There were 2 successful login(s) from 1 account(s) and 1 IP address(es)
The top username(s) were:
      2 realusername
The top IP(s) were:
      2 xxx.xxx.xxx.xxx  :  US, United States        

There were 63 failed login(s) from 1 account(s) and 55 IP address(es)
The top username(s) were:
      7 admin
      4 www
      4 user
      3 ftpuser
      2 zabbix
The top IP(s) were:
      6 185.254.122.114  :  IP Address not found     BANNED
      2 41.231.56.98     :  TN, Tunisia              BANNED
      2 167.99.8.158     :  US, United States        
      2 104.196.16.112   :  US, United States        
      1 91.122.14.178    :  RU, Russian Federation   

Fail2Ban blocked 2 IP address(es) that attempted to connect too much
```

## Setup
* The script assumes your auth logs are at /var/log/ and you have auth.log, auth.log.1, fail2ban.log, and fail2ban.log.1
* You must have geoiplookup installed (updating the database with geoipupdate is probably also smart)
* You must have fail2ban installed and running (or the fail2ban part won't work)
* Simple method is to call the script from the cmdline for a report printed to stdout
* Or use the included cron script (place in /etc/cron.daily/), configure the script, and configure sendmail for sending email
* There are comments in the cron script explaining what needs to be configured

## Thanks
* SMTP Provided by Mailgun  [mailgun](https://www.mailgun.com/)
* IP Lookup with GeoLite2 from MaxMind
> This product includes GeoLite2 data created by MaxMind, available from [maxmind.com](https://www.maxmind.com)

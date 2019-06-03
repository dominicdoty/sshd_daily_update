# sshd_daily_update
A simple script that provides a daily update for the system admin including:
* checks for available updates
* auth log analysis (looking at ssh only)
* fail2ban log analysis (looking for new bans)
* daily run of rkhunter

Example output:
```
UPDATES:
0 updates can be installed immediately.
0 of these updates are security updates.

LOG ANALYSIS:
Analyzing logs from May 28 00:00:01 to May 28 23:59:59

There were 2 successful login(s) from 1 account(s) and 1 IP address(es)
The top username(s) were:
   2 realusername
The top IP(s) were:
   2 xxx.xxx.xxx.xxx  :  Los Angeles California, US        

There were 63 failed login(s) from 1 account(s) and 55 IP address(es)
The top username(s) were:
   24 root
   7 admin
   4 www
   4 user
   3 ftpuser
   2 zabbix
The top IP(s) were:
   3 68.183.150.54   : Clifton New Jersey, US : BANNED
   3 128.199.182.235 : Singapore , SG : 
   2 58.59.2.26      :  Shandong, CN : BANNED
   2 51.68.230.54    :  , FR : 
   2 46.101.127.49   : Frankfurt am Main Hesse, DE : BANNED

24 attempts on real account root
4 attempts on real account www

FAIL2BAN ANALYSIS:
Blocked 3 IP address(es)

RKHUNTER RESULTS:
System checks summary
=====================

File properties checks...
    Files checked: 147
    Suspect files: 0

Rootkit checks...
    Rootkits checked : 500
    Possible rootkits: 0
```

## Setup
* Simple: Run install.sh (./install.sh) it should verify all dependencies and copy files to appropriate locations (written for Ubuntu Server)
* The script assumes your auth logs are at /var/log/ and you have auth.log, auth.log.1, fail2ban.log, and fail2ban.log.1
* You must have fail2ban installed and running
* You must have rkhunter installed and indexed
* You must have an API key for ipstack.com
* Simple method is to call the script from the cmdline for a report printed to stdout
* Or use the included cron script (place in /etc/cron.daily/), configure the script, and configure sendmail for sending email
* There are comments in the cron script explaining what needs to be configured

## Arguments
* -m : email formatting (include header and HTML stuff)
* -e : "TO:" email address to put in header
* -r : run rkhunter

## Thanks
* SMTP Provided by Mailgun  [mailgun](https://www.mailgun.com/)
* IP Lookup with [ipstack.com](https://www.ipstack.com/) (FREE! and more detailed results than GeoLite2)

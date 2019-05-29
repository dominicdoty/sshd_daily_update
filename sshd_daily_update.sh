#!/bin/bash

cd /tmp

RKHUNT='false'
SENDMAILFLAG='false'
EMAIL="$USER@$HOSTNAME"

##ARGUMENT HANDLING
while getopts 'me:r' flag; do
  case "${flag}" in
    m) SENDMAILFLAG='true' ;;
    e) EMAIL="${OPTARG}" ;;
    r) RKHUNT='true' ;;
  esac
done

##START RKHUNTER IN BACKGROUND
if [ "$RKHUNT" = "true" ]; then
	rkhunter --check --enable all -q --sk --summary > rkhunt.log &
	PID=$!
fi

##HTML HEADER JUNK
if [ "$SENDMAILFLAG" = "true" ]; then
	echo "From: $USER@$HOSTNAME"
	echo "To: $EMAIL"
	echo "Subject: Daily Log Analysis"
	echo "MIME-Version: 1.0"
	echo "Content-Type: text/html"
	echo "Content-Disposition: inline"
	echo "<html>"
	echo "<body>"
	echo "<pre style=\"font: monospace\">"
fi

# Create a Logfile with the last day
grep "`date --date='1 days ago' +"%b %e"`" /var/log/auth.log.1 > day.log
grep "`date --date='1 days ago' +"%b %e"`" /var/log/auth.log >> day.log

# How many hours the logs cover
echo -n "Analyzing logs from "
head -n 1 day.log | grep -P -o "\S+ \w+ (\d{2}:){2}\d{2}" | tr -d '\n' # Start
echo -n " to "
tail -n 1 day.log | grep -P -o "\S+ \w+ (\d{2}:){2}\d{2}" # End
echo ""

##SUCCESS SECTION
# Grab successful logins and put them in a file
grep "Accepted" day.log > successful_auths.log

# How many successful logins there were
successful_auths_count=$(wc -l < successful_auths.log | tr -d '\n')

# How many successful unique usernames there were
successful_users_count=$(cut -d " " -f 9 successful_auths.log | sort | uniq | wc -l | tr -d '\n')

# How many successful unique IPs there were
successful_ips_count=$(cut -d " " -f 11 successful_auths.log | sort | uniq | wc -l | tr -d '\n')

# Print words
printf "There were %d successful login(s) from %d account(s) and %d IP address(es)\n" "$successful_auths_count" "$successful_users_count" "$successful_ips_count"

# Skip printing "Top users" if nobody logged in
if [ "$successful_auths_count" != "0" ]; then

	# What were the top successful usernames
	echo "The top username(s) were:"
	cut -d " " -f 9 successful_auths.log | sort | uniq -c | sort -nr | head -n 5

	# What were the top successful IPs
	echo "The top IP(s) were:"
	cut -d " " -f 11 successful_auths.log | sort | uniq -c | sort -nr | head -n 5 > successful_ips.log

	while read line; do
		location=$(echo "$line" | cut -d " " -f 2 | xargs geoiplookup | cut -d: -f 2)
		printf "      %-18s : %-25s %s\n" "$line" "$location"
	done < successful_ips.log

	echo ""
else
	echo ""
fi


##FAIL2BAN PREP
# Create a Logfile with the last day
grep "`date --date='1 days ago' +"%F"`" /var/log/fail2ban.log.1 | grep Ban > fail2ban_day.log
grep "`date --date='1 days ago' +"%F"`" /var/log/fail2ban.log | grep Ban >> fail2ban_day.log

##FAILURE SECTION
# Grab failed logins and put them in a file
grep "Invalid" day.log > failed_auths.log

# How many failed logins there were
failed_auths_count=$(wc -l < failed_auths.log | tr -d '\n')

# How many failed unique usernames there were
failed_users_count=$(cut -d " " -f 11 failed_auths.log | sort | uniq | wc -l | tr -d '\n')

# How many failed unique IPs there were
failed_ips_count=$(cut -d " " -f 10 failed_auths.log | sort | uniq | wc -l | tr -d '\n')

# Print words
printf "There were %d failed login(s) from %d account(s) and %d IP address(es)\n" "$failed_auths_count" "$failed_users_count" "$failed_ips_count"


# Skip printing "Top users" if nobody logged in
if [ "$failed_auths_count" != "0" ]; then

	# What were the top failed usernames
	echo "The top username(s) were:"
	cut -d " " -f 8 failed_auths.log | sort | uniq -c | sort -nr | head -n 5

	# What were the top failed IPs
	echo "The top IP(s) were:"
	cut -d " " -f 10 failed_auths.log | sort | uniq -c | sort -nr | head -n 5 > failed_ips.log

	while read line; do
	        location=$(echo "$line" | cut -d " " -f 2 | xargs geoiplookup | cut -d: -f 2 | tr -d '\n')

		if grep -q `echo "$line" | cut -d " " -f 2` fail2ban_day.log;then
			banned="BANNED"
		else
			banned=""
		fi

		printf "      %-18s : %-25s %s\n" "$line" "$location" "$banned"
	done < failed_ips.log

	echo ""
else
	echo ""
fi


##FAIL2BAN SECTION
# Count number of bans
fail2ban_bans=$(grep "] Ban" fail2ban_day.log | wc -l)

# Print words
printf "Fail2Ban blocked %d IP address(es) that attempted to connect too much\n" "$fail2ban_bans"


##RKHUNTER SECTION
# Wait for rkhunter and print report
if [ "$RKHUNT" = "true" ]; then
	wait $PID
	cat rkhunt.log | head -n 11
fi

##HTML END STUFF
if [ "$SENDMAILFLAG" = "true" ]; then
	echo "</pre>"
	echo "</body>"
	echo "</html>"
fi

##CLEAN UP
rm -f day.log
rm -f successful_auths.log
rm -f successful_ips.log
rm -f failed_auths.log
rm -f failed_ips.log
rm -f fail2ban_day.log
rm -f rkhunt.log

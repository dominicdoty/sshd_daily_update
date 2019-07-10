#!/bin/bash

cd /tmp

RKHUNT='false'
SENDMAILFLAG='false'
EMAIL="$USER@$HOSTNAME"

##ARGUMENT HANDLING
while getopts 'hme:r' flag; do
  case "${flag}" in
	h) HELP='true' ;;
    m) SENDMAILFLAG='true' ;;
    e) EMAIL="${OPTARG}" ;;
    r) RKHUNT='true' ;;
  esac
done


##HELP
if [ "$HELP" = "true" ]; then
	echo "SSHD DAILY UPDATE - basic daily log report and admin"
	echo "   run with no args for a report to stdout, add -r for rkhunter, add email options to pipe to sendmail"
	echo "   -m : email formatting (include header/HTML junk)"
	echo "   -e : TO email address for putting in email header (with -m option)"
	echo "   -r : run rkhunter"
	exit 0
fi


##START RKHUNTER IN BACKGROUND
if [ "$RKHUNT" = "true" ]; then
	sudo rkhunter --check --enable all -q --sk --summary > rkhunt.log &
	PID=$!
fi

##HTML HEADER JUNK
if [ "$SENDMAILFLAG" = "true" ]; then
	echo "From: logupdates@$HOSTNAME"
	echo "To: $EMAIL"
	echo "Subject: Daily Log Analysis"
	echo "MIME-Version: 1.0"
	echo "Content-Type: text/html"
	echo "Content-Disposition: inline"
	echo "<html>"
	echo "<body>"
	echo "<pre style=\"font: monospace\">"
fi

##UPDATES STATUS
echo -n "UPDATES:"
sudo cat /var/lib/update-notifier/updates-available

# Create a Logfile with the last day
grep -a "`date --date='1 days ago' +"%b %e"`" /var/log/auth.log.1 > day.log
grep -a "`date --date='1 days ago' +"%b %e"`" /var/log/auth.log >> day.log

# How many hours the logs cover
echo "LOG ANALYSIS:"
echo -n "Analyzing logs from "
head -n 1 day.log | grep -a -P -o "^(\S+\s+\S+\s+\S+)" | tr -d '\n'	# Start
echo -n " to "
tail -n 1 day.log | grep -a -P -o "^(\S+\s+\S+\s+\S+)" 				# End
echo ""

##SUCCESS SECTION
# Grab successful logins and put them in a file
grep -a "Accepted" day.log > successful_auths.log

# How many successful logins there were
successful_auths_count=$(wc -l < successful_auths.log | tr -d '\n')

# How many successful unique usernames there were
successful_users_count=$(grep -oP "for \K\S+" successful_auths.log | sort | uniq | wc -l | tr -d '\n')

# How many successful unique IPs there were
successful_ips_count=$(grep -oP "from \K[0-9\.]+" successful_auths.log | sort | uniq | wc -l | tr -d '\n')

# Print words
printf "There were %d successful login(s) from %d account(s) and %d IP address(es)\n" "$successful_auths_count" "$successful_users_count" "$successful_ips_count"

# Skip printing "Top users" if nobody logged in
if [ "$successful_auths_count" != "0" ]; then

	# What were the top successful usernames
	echo "The top username(s) were:"
	grep -a -oP "for \K(\S+)" successful_auths.log | sort | uniq -c | sort -nr | head -n 5 | sed -E 's/^( +)/   /g'

	# What were the top successful IPs
	echo "The top IP(s) were:"
	grep -a -oP "from \K(\S+)" successful_auths.log | sort | uniq -c | sort -nr | head -n 5 > successful_ips.log

	while read line; do
		line_ip=$(echo "$line" | cut -d " " -f 2)
		ipstack_resp=$(ipstack.sh -i "$line_ip")
		city=$(grep -a -oP "city\":\"\K([^\"]+)" <<< "$ipstack_resp")
		region=$(grep -a -oP "region_name\":\"\K([^\"]+)" <<< "$ipstack_resp")
		country=$(grep -a -oP "country_code\":\"\K([^\"]+)" <<< "$ipstack_resp")
		printf "   %-18s: %s %s, %s\n" "$line" "$city" "$region" "$country"
	done < successful_ips.log

	echo ""
else
	echo ""
fi


##FAIL2BAN PREP
# Create a Logfile with the last day
grep -a "`date --date='1 days ago' +"%F"`" /var/log/fail2ban.log.1 | grep -a Ban > fail2ban_day.log
grep -a "`date --date='1 days ago' +"%F"`" /var/log/fail2ban.log | grep -a Ban >> fail2ban_day.log


##FAILURE SECTION
# Grab failed logins and put them in a file
grep -a "Disconnected .\+ \[preauth\]" day.log > failed_auths.log

# How many failed logins there were
failed_auths_count=$(wc -l < failed_auths.log | tr -d '\n')

# How many failed unique usernames there were
failed_users_count=$(grep -a -oP "user \K\S+" failed_auths.log | sort | uniq | wc -l | tr -d '\n')

# How many failed unique IPs there were
failed_ips_count=$(grep -a -oP "user \S+ \K\S+" failed_auths.log | sort | uniq | wc -l | tr -d '\n')

# Print words
printf "There were %d failed login(s) from %d account(s) and %d IP address(es)\n" "$failed_auths_count" "$failed_users_count" "$failed_ips_count"


# Skip printing "Top users" if nobody logged in
if [ "$failed_auths_count" != "0" ]; then

	# What were the top failed usernames
	echo "The top username(s) were:"
	grep -a -oP "user \K\S+" failed_auths.log | sort | uniq -c | sort -nr | sed -E 's/^( +)/   /g' > failed_usernames.log
	cat failed_usernames.log | head -n 5

	# What were the top failed IPs
	echo "The top IP(s) were:"
	grep -a -oP "user \S+ \K\S+" failed_auths.log | sort | uniq -c | sort -nr | head -n 5 > failed_ips.log

	while read line; do
	    line_ip=$(echo "$line" | grep -oP "\S+ \K\S+")
		ipstack_resp=$(ipstack.sh -i "$line_ip")
		city=$(grep -a -oP "city\":\"\K([^\"]+)" <<< "$ipstack_resp")
		region=$(grep -a -oP "region_name\":\"\K([^\"]+)" <<< "$ipstack_resp")
		country=$(grep -a -oP "country_code\":\"\K([^\"]+)" <<< "$ipstack_resp")

		if grep -a -q "$line_ip" fail2ban_day.log; then
			banned="BANNED"
		else
			banned=""
		fi

		printf "   %-18s: %s %s, %s : %s\n" "$line" "$city" "$region" "$country" "$banned"
	done < failed_ips.log

	echo ""

	# Print failed logins to real users
	while read line; do
		if grep -a -oP "^\w+" /etc/passwd | grep -a -q "^"`echo "$line" | cut -d " " -f 2`"$"; then
			count=$(echo "$line" | grep -a -oP "^\w+")
			user=$(echo "$line" | grep -a -oP "\w+$")
			printf "%d attempts on real account %s\n" "$count" "$user"
		fi
	done < failed_usernames.log
	echo ""

else
	echo ""
fi


##FAIL2BAN SECTION
# Count number of bans
fail2ban_bans=$(grep -a "] Ban" fail2ban_day.log | wc -l)

# Print words
echo "FAIL2BAN ANALYSIS:"
printf "Blocked %d IP address(es)\n\n" "$fail2ban_bans"


##RKHUNTER SECTION
# Wait for rkhunter and print report
if [ "$RKHUNT" = "true" ]; then
	echo -n "RKHUNTER RESULTS:"
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
rm -f failed_usernames.log
rm -f fail2ban_day.log
rm -f rkhunt.log

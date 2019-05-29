### Quick Script to Install the log analysis tool

## Check for prereqs
echo "Checking for prereqs:"

echo -n "rkhunter "
command -v rkhunter > /dev/null 2>&1 || { echo >&2 "[BAD] rkhunter not installed, do sudo apt install rkhunter"; exit 1; }
echo "[OK]"

echo -n "geoiplookup "
command -v geoiplookup > /dev/null 2>&1 || { echo >&2 "[BAD] geoiplookup not installed, do sudo apt install geoiplookup"; exit 1; }
echo "[OK]"

echo -n "fail2ban "
command -v fail2ban-server > /dev/null 2>&1 || { echo >&2 "[BAD] fail2ban not installed, do sudo apt install fail2ban"; exit 1; }
echo "[OK]"

## Check for running fail2ban
echo -n "Checking for running fail2ban "
pgrep fail2ban > /dev/null 2>&1 || { echo >&2 "[BAD] fail2ban does not appear to be running, please configure"; exit 1; }
echo "[OK]"

## Check for log file existence
echo -n "Checking for /var/log/auth.log "
test -f /var/log/auth.log || { echo >&2 "[BAD] log does not exist"; exit 1; }
echo "[OK]"

echo -n "Checking for /var/log/auth.log.1 "
test -f /var/log/auth.log.1 || { echo >&2 "[BAD] log does not exist"; exit 1; }
echo "[OK]"

echo -n "Checking for /var/log/fail2ban.log "
test -f /var/log/fail2ban.log || { echo >&2 "[BAD] log does not exist"; exit 1; }
echo "[OK]"

echo -n "Checking for /var/log/fail2ban.log.1 "
test -f /var/log/fail2ban.log.1 || { echo >&2 "[BAD] log does not exist"; exit 1; }
echo "[OK]"

## Copy to /usr/bin
echo -n "Copying sshd_daily_update.sh to /usr/bin/ "
sudo cp sshd_daily_update.sh /usr/bin/sshd_daily_update.sh || { echo >&2 "[BAD] copying failed"; exit 1; }
echo "[OK]"

## Do Cron setup
read -p "Do you want daily email reports as a cron entry? [Y/n]: " CRONYES

if [ "$CRONYES" = "" ] || [ "$CRONYES" = "y" ] || [ "$CRONYES" = "Y" ]; then
	read -p "Please input the email to send daily report to: " EMAIL

	if [ "$EMAIL" = "" ]; then
		echo >&2 "Empty Email, failure"
		exit 1
	else
		sed -e 's/youremailhere@gmail.com/'"$EMAIL"'/g' cron_sshd_daily_update > cron_sshd_daily_update_tmp
		sudo mv cron_sshd_daily_update_tmp /etc/cron.daily/cron_sshd_daily_update
		echo "Script setup to run by move to /etc/cron.daily"

		echo -n "Updating permissions for cron invocation script "
		sudo chown root:root /etc/cron.daily/cron_sshd_daily_update|| { echo >&2 "[BAD] Failed to update owner to root"; exit 1; }
		sudo chmod 755 /etc/cron.daily/cron_sshd_daily_update|| { echo >&2 "[BAD] Failed to update permissions to 755"; exit 1; }
		echo "[OK]"
	fi
fi

## Permissions Update
echo -n "Updating permissions for script "
sudo chown root:root /usr/bin/sshd_daily_update.sh || { echo >&2 "[BAD] Failed to update script owner to root"; exit 1; }
sudo chmod 755 /usr/bin/sshd_daily_update.sh || { echo >&2 "[BAD] Failed to update permissions to 755"; exit 1; }
echo "[OK]"

## All Done
echo "Complete!"

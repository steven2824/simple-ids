#!/usr/bin/bash

LOG_FILE="/var/log/sus_logins.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

(
	last=$(who -u | awk '$1 == "root" { print $1 "|" $2 "|" $6 "|" $NF }' | sort)
	while true; do
		current=$(who -u | awk '$1 == "root" { print $1 "|" $2 "|" $6 "|" $NF }' | sort)
		if [ -n "$last" ]; then
			new_logins=$(comm -13 <(echo "$last" | sort) <(echo "$current" | sort))
			if [ -n "$new_logins" ]; then
				timestamp=$(date '+%Y-%m-%d %H:%M:%S')

				while IFS='|' read -r user tty pid ip; do
					[ -z "$line" ] && continue

					alert="User: $user | TTY: tty | PID: $pid | Source: $ip"
					echo "[$timestamp] ROOT LOGIN: $alert" >> "LOG_FILE"
					echo -e "\n\033[1;31m ROOT LOGIN:\033[0m $alert" | wall 2>/dev/null
				done <<< "$new_logins"
			fi
		fi
		last="$current"
		sleep 1
	done
) & disown

PID=$!
echo "IDS running with PID $PID"
echo "Logging to $LOG_FILE"

#!/usr/bin/bash

LOG_FILE="/var/log/sus_logins.log"
MY_TTY=$(tty)
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

# change to true if you want new root sessions to be immediately killed
INSTANT_KILL=false

(
	last=$(who -u | awk '$1 == "root" { print $1 "|" $2 "|" $6 "|" $NF }' | sort)
	while true; do
		current=$(who -u | awk '$1 == "root" { print $1 "|" $2 "|" $6 "|" $NF }' | sort)
		if [ -n "$last" ]; then
			new_logins=$(comm -13 <(echo "$last" | sort) <(echo "$current" | sort))
			if [ -n "$new_logins" ]; then
				timestamp=$(date '+%Y-%m-%d %H:%M:%S')

				while IFS='|' read -r user tty pid ip; do
					[ -z "$user" ] && continue

					alert="User: $user | TTY: $tty | PID: $pid | IP: $ip"
					echo "[$timestamp] ROOT LOGIN: $alert" >> "$LOG_FILE"
					echo -e "[ROOT LOGIN: $alert\n]" > "$MY_TTY" 2>/dev/null

					if $INSTANT_KILL; then
						if [ "$tty" != "${MY_TTY#/dev/}" ]; then
							kill -9 $pid 2>/dev/null
							echo "Killed PID $pid from IP $ip" >> "$LOG_FILE"
							echo -e "Killed PID $pid from IP $ip" > "$MY_TTY" 2>/dev/null
						fi
					fi

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

# source lib_alarm.sh
# ----- Time Calculations and Formatting

# UTC is how standard Unix systems store the date/time in the real time clock.
#     use timedatectl to get all information

# man date
#   date [OPTION]... [+FORMAT]
#     -d     use this date
#     +      use this format for result
#     %s     seconds since 1970-01-01 00:00:00 UTC
#  to convert back: date -d @$seconds

# ----- Primitives

tz_abrev() {
	date +%Z # e.g. "PDT"
}

tz_numeric() {
	date +%z # e.g. "-0700"
}

tz_seconds() {
	# param $1: the return value from date +%z
	# return: offset, in seconds, as an integer.
	case "$1" in
	'-0800') echo $((-8 * 3600)) ;;
	'-0700') echo $((-7 * 3600)) ;;
	'-0600') echo $((-6 * 3600)) ;;
	'-0500') echo $((-5 * 3600)) ;;
	'-0400') echo $((-4 * 3600)) ;;
	'-0300') echo $((-3 * 3600)) ;;
	'-0200') echo $((-2 * 3600)) ;;
	'-0100') echo $((-1 * 3600)) ;;
	'0000') echo $((0 * 3600)) ;;
	*) echo "error in tz_seconds" ;;
	esac
}

tz_adj_secs() {
	# return num seconds from locat time zone to UTC
	tz_seconds "$(tz_numeric)"
}

now_epoch_dts() {
	date +%s
}

now_local_dts() {
	# now in local time expressed in seconds
	local tz toff
	tz=$(now_epoch_dts)
	toff=$(tz_adj_secs)
	echo $((tz + toff))
}

now_midnight_dts() {
	# return seconds at 'start of local day' to establish
	#   a day base reference in local seconds
	# params: none
	local midnight tz_off
	# get UTC time at midnight
	midnight=$(date -d 'today 00:00:00' '+%s')
	# adjust for time zone
	tz_off=$(tz_adj_secs)
	midnight=$((midnight + tz_off))
	echo "$midnight"
}

# ----- Formatting based on primitives

secs_fmt() {
	# format given seconds to specified format
	local secs="$1"
	# local fmt="$2" || "%Y-%m-%d_%H:%M:%S"
	local fmt="%Y-%m-%d_%H:%M:%S"
	date -u -d @"${secs}" +"$fmt"
}

secs2date_fmt() {
	# convert from secs to HMS
	# param:  $1  time in seconds to format
	# param:  $2  type of format (1 2 3 4 5 6)
	# output: seconds formatted into days, hours, minutes, seconds
	# echo "- secs2date p1 debug: $1" >>"$fdebug"
	# echo "- secs2date p2 debug: $2" >>"$fdebug"
	local ss mm hh dd
	ss=$(($1 % 60))
	mm=$((($1 % 3600) / 60))    # 3600 / 60 = 60
	hh=$((($1 % 86400) / 3600)) # 86400 / 3600 = 24
	dd=$(($1 / 86400))

	case $2 in
	1) printf -v result "%01dd %02d:%02d:%02d" $dd $hh $mm $ss ;;
	2) printf -v result "%02d:%02d:%02d" $hh $mm $ss ;;
	3) printf -v result "%02d:%02d" $hh $mm ;;
	4) printf -v result "%02d" $hh ;;
	5) printf -v result "%02d" $mm ;;
	6) printf -v result "%02d" $ss ;;
	7) printf -v result "%02d:%02d" $mm $ss ;;
	*)
		local error="ERROR: no valid format specified"
		echo "$error" >>"$fdebug"
		new_error_msg "$error"
		;;
	esac
	echo "$result"
}

time_diff_fmt() {
	# difference between $1 and $2.
	# param: $1  earlier time in seconds
	# param: $2  later time in seconds
	# param: $3  output format
	local diff fmt
	diff=$(($2 - $1))
	fmt=$(secs2date_fmt "$diff" "$3")
	echo "$fmt"
}

# ---------------------

hms2secs() {
	# convert HMS time  to seconds
	# Results in offset secs into day.
	# param: $1    hours
	# param: $2    minutes
	# param: $3    seconds
	local hr mm ss secs
	# hr=$1
	# mm=$2
	# ss=$3
	hr=$(clean_digits "$1")
	mm=$(clean_digits "$2")
	ss=$(clean_digits "$3")

	# echo $(((hr * 60 * 60) + (mm * 60) + ss)) >> "$fdebug"
	secs=$(((hr * 60 * 60) + (mm * 60) + ss))
	echo "$secs"
}

#)
fdebug="var/debug.txt"
echo "" >"$fdebug"
# ----- Alarm functions
# hms -> seconds in 24h hours format
# dts -? seconds in epoch format

hr_alarm= # specs for current event 24h clock
mm_alarm=
ss_alarm=
hms_alarm_secs=0
alarm_dts=0 # <-- this is where alarm trigger time is stored

set_alarm_dts() {
	alarm_dts=$1
	echo "$alarm_dts"
}

get_alarm_dts() {
	echo "$alarm_dts"
}

get_alarm_dts_fmt() {
	# return formatted alarm time 2
	# params: none
	local result
	result=$(secs2date_fmt "$alarm_dts" "2")
	echo "$result"
}

tm2alarm_secs() {
	tm2event_secs "$alarm_dts"
}

tm2alarm_fmt() {
	# time from 'now' to next alarm in chosen format
	# return the formatted result
	# params: $1 - format specifier for result
	local secs fmt
	secs=$(tm2alarm_secs)
	fmt=$(secs2date_fmt "$secs" "$1")
	echo "$fmt"
}

# event_hms2secs() { # ???
# 	hms_alarm_secs=$(hms2secs "$hr_alarm" "$mm_alarm" "$ss_alarm")
# }

event_hms2dts() {
    # return: alarm_dts
	hms_alarm_secs=$(hms2secs "$hr_alarm" "$mm_alarm" "$ss_alarm")
	alarm_dts=$(($(now_local_dts) + hms_alarm_secs))
}

tm2event_secs() {
	# time from 'now' to next alarm expressed as seconds
	# return difference in seconds
	# params: $1 local time of event in seconds
	local now_secs event_secs diff
	event_secs=$1
	now_secs=$(now_local_dts)
	diff=$((event_secs - now_secs))
	echo "$diff"
}

# now_as_secs
# now_day_secs() { # TODO RETIRE
# 	#  "current time" expressed as seconds into the day (with respect to start of day)
# 	#  params: none
# 	local now_secs
#
# 	# echo "now day sesc" >>"$fdebug"
# 	# now_secs=$(($(date +%s) - $(now_midnight_dts)))
# 	now_secs=$(($(now_local_dts) - $(now_midnight_dts)))
# 	echo "$now_secs"
# }

# tm2alarm_as_secs() { # RETIRE
# 	# time from 'now' to next alarm expressed as seconds
# 	# return difference in seconds
# 	# params: none
# 	local now_secs alarm_secs diff
# 	now_secs=$(now_day_secs)
# 	# now_secs=$(now_local_dts)
# 	alarm_secs=$(alarm_time_as_secs)
# 	diff=$((alarm_secs - now_secs))
# 	echo "$diff"
# }
#
# alarm_time_fmt() { # RETIRE
# 	# alarm time using format specifier 2
# 	secs2date_fmt "$(alarm_time_as_secs)" 2
# }
#
# alarm_time_as_secs() { # RETRE
# 	# "alarm time" expressed as seconds
# 	# params: none
# 	# local secs
# 	# secs=$(hms2secs "$hr_alarm" "$mm_alarm" "$ss_alarm")
# 	# echo "$secs"
# 	hms2secs "$hr_alarm" "$mm_alarm" "$ss_alarm"
# }

# ----- Testing



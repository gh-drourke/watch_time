source lib_time.sh
# -- global authority on the alarm time and status

alarm_enabled=0 # alarm is off / on via press 'o'
alarm_id=0      # the current alarm id
# hr_alarm=       # specs for current alarm
# mm_alarm=
# ss_alarm=
alarm_msg=
alarm_state=0
# alarm state  = 0 -> initial
#                1 -> running
#                2 -> expired
#                3 -> destroyed
alarm_rung= # has the alarm run

clean_digits() {
	# input $1  - assuming digits
	# on blank input -> output '0'
	if [[ "${#1}" -eq 0 ]]; then # zero-length check
		echo "0"
	else
		local a1
		a1=$1
		a1="${a1//[^0-9]/}" # remove non digits
		# a1="${a1##+([[:space:]])}"
		a1=$(echo "$a1" | sed 's/^0*//') # remove leading zeros
		if [[ -z $a1 ]]; then
			echo "0"
		else
			echo "$a1"
		fi
	fi
}

find_largest_num_in_file() {
	# parameter(s): $1 - name of file to search
	local ww xx yy result

	ww=$(awk '{print $2}' <"$1")
	xx=$(echo "$ww" | sed 's/\[//' | sed 's/\]//')
	yy=$(echo "$xx" | sort -nur)
	result=$(echo "$yy" | head -1)

	if [ -z "$yy" ]; then
		echo '0'
	else
		echo "$result"
	fi
}

get_next_alarm_id() {
	# parameter(s): $1 -> file to search
	local n
	n=$(find_largest_num_in_file "$1")
	echo $((n + 1))
}

is_alarm_valid() {
	# Ensure alarm settings are able to run
	# param $1: alarm_dts
	local now alarm_tm
	now=$(now_local_dts)
	alarm_tm=$1
	result=$((alarm_tm - now))
	echo "is alarm valid: $result" >>"$fdebug"
	if [[ result -ge 0 ]]; then
		echo true
	else
		echo false
	fi
}

calc_dts_new() {
	# params: $1 hh, $2 mm, #3 ss, #4 offset = true
	# offset = false: use midnight base
	# offset = true: use offset base

	local hhh mmm sss offset
	offset=$4

	echo "raw inputs:               $1:$2:$3" >>"$fdebug"
	hhh=$(clean_digits "$1")
	mmm=$(clean_digits "$2")
	sss=$(clean_digits "$3")
	echo "clean inputs:              $hhh:$mmm:$sss" >>"$fdebug"

	local tsecs dts dtsf
	tsecs=$(hms2secs "$hhh" "$mmm" "$sss")
	echo "  tsecs                       $tsecs " >>"$fdebug"

	if [[ $offset == true ]]; then
		dts=$(now_local_dts)
	else
		dts=$(now_midnight_dts)
	fi
	dtsf=$(secs_fmt "$dts")
	echo "  dts format                  $dtsf" >>"$fdebug"

	dts_new=$(("$dts" + "$tsecs"))
	if [[ $(is_alarm_valid "$dts_new") == false ]]; then
		tsecs=$((tsecs + 86400)) # add one day
		dts_new=$(("$dts" + "$tsecs"))
		echo "  one day upgrade             $tsecs " >>"$fdebug"
	fi
	dtsf=$(secs_fmt "$dts_new")
	echo "  dts_new fmt                 $dtsf" >>"$fdebug"
	echo "  dts_new                     $dts_new" >>"$fdebug"
	# echo "$dts_new"

	if [[ $(is_alarm_valid "$dts_new") == true ]]; then
		echo "conf: alarm valid" >>"$fdebug"
		create_alarm "$dts_new" "$msg"
	else
		echo "conf: alarm invalid" >>"$fdebug"
		local msg
		msg="INFO: config timer: no entry"
		new_error_msg "$msg"
		echo "$msg" >>"$fdebug"
	fi
}

configure_timer() {
	# parameter(s): none
	# return value: none
	clear_error_msg
	wipe_input

	tput cup "$input_line_start"
	tput cnorm

	local hh mm ss msg
	echo -n "${lgn}offset hour:     ${lgb}"
	read -r hh
	echo -n "${lgn}offset minutes:  ${lgb}"
	read -r mm
	echo -n "${lgn}offset seconds:  ${lgb}"
	read -r ss
	echo -n "${lgn}message:  ${lgb}"
	read -r msg


	echo "--- config_timer()" >>"$fdebug"

	local quit="q"
	if [[ $hh = "$quit" || $mm = "$quit" || $ss = "$quit" ]]; then
		new_error_msg "INFO: config timer: quit"
		echo "quit" >>"$fdebug"
	else
		calc_dts_new "$hh" "$mm" "$ss" true
	fi

	wipe_input
}

configure_alarm() {
	# parameter(s): none
	# return value: none
	clear_error_msg
	wipe_input

	tput cup "$input_line_start"
	tput cnorm

	local hh mm msg
	echo -n "${lgn}alarm hour:     ${lgb}"
	read -r hh
	echo -n "${lgn}alarm minute:   ${lgb}"
	read -r mm
	echo -n "${lgn}alarm message   ${lgb}"
	read -r msg

	echo "--- config_alarm()" >>"$fdebug"

	local quit="q"
	if [[ $hh = "$quit" || $mm = "$quit" || $ss = "$quit" ]]; then
		new_error_msg "config alarm: quit"
	else
		calc_dts_new "$hh" "$mm" "$ss" false
	fi

	wipe_input
}

create_alarm() {
	# params $1 alarm_dts
	# param: $2 message
	# Alarm must be set to a future time!
	local hhh mmm sss
	local msg="$2"

	{ echo -e "\n--- create alarm" >>"$fdebug"; }
	echo -e "param dts               $1" >>"$fdebug"
	echo -e "param message           $2" >>"$fdebug"

	alarm_state=0
	alarm_rung=0

	if [[ $(is_alarm_valid "$1") == true ]]; then
		# TODO Future: Add to queue
		alarm_id=$(get_next_alarm_id "$log")
		alarm_enabled=1
		alarm_state=1

		set_alarm_dts "$1"
		echo "get_alarm_dts:  $(get_alarm_dts)" >>"$fdebug"

		if [[ $msg == '' ]]; then
			alarm_msg="<no msg>"
		else
			alarm_msg="$msg"
		fi
		echo "alarm [$alarm_id] start:     $(date +'%Y-%m-%d %H:%M:%S')" " -- $alarm_msg" >>"$log"
	else
		alarm_enabled=0
		alarm_state=0
	fi
}

reset_alarm() {
	alarm_msg=""
	set_alarm_dts 0
}

## Expired alarm tracking

_expired_secs=0 # seconds since expiration

start_expired_secs() {
	_expired_secs=$(now_epoch_dts)
}

tmFromalarm_fmt() {
	local delta fmt
	delta=$(($(now_epoch_dts) - _expired_secs))

	if [[ $delta -lt 60 ]]; then
		fmt=$(secs2date_fmt "$delta" "6")
	elif
		[[ $delta -lt 3600 ]]
	then
		fmt=$(secs2date_fmt "$delta" "7")
	elif
		[[ $delta -lt 86400 ]]
	then
		fmt=$(secs2date_fmt "$delta" "2")
	else
		fmt=$(secs2date_fmt "$delta" "1")
	fi
	echo "$fmt"
}

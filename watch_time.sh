#!/bin/bash

version="0.301"
# watch time:
# better ./install/install.sh script

#-- Display

# on my terminal: infocmp -1 ansi | grep sgr0= --> \E[0;10m,]
reset="$(tput sgr0)"
bold="$(tput bold)"
dim="$(tput dim)"
f_red="$(tput setaf 1)"
f_green="$(tput setaf 2)"
f_cyan="$(tput setaf 6)"

cl2eol="$(tput el)"
cl_ln="\033[0K\r"
# clear="\r\033[K"
# clear_screen="\033[H\033[J"
# b_red=$(tput setab 1)

ldm="${dim}"                    # label dim
lgb="${reset}${bold}${f_green}" # label green bold
lgn="${reset}${f_green}"        # label green normal
lgd="${reset}${f_green}${dim}"  # label green dim
lnr="${reset}"                  # label normal
lnd="${reset}${dim}"            # label normal dim
lrb="${reset}${bold}${f_red}"   # label red bold
# lrd="${reset}${dim}${f_red}"    # label red dim
ler="${reset}${f_cyan}${ldm}" # label for errors
lcy="${reset}${f_cyan}${ldm}" # label for errors

# commandline_args=("$@")

err_msg=
info_area_state=0
#               0 - clear
#               1 - system status
#               2 - menu
#               3 - notes        #
#               4 - clock
#               5 - count down alarm clock

# Area definitions - start lines
err_line_start=5
input_line_start=9
info_line_start=14

# ---- Utilities

finish() {
	if [[ $(is_alarm_running) == 1 ]]; then
		destroy_alarm
	fi
	tput reset
	printf "\nWatch Time exit!\n"
}

on_size_change() {
	clear
}

# trap finish EXIT
trap on_size_change WINCH

pause() {
	echo
	local msg
	msg="${lgn}Press any key to continue ..."
	if [[ -z $1 ]]; then
		read -rs -n 1 -p "$msg"
	else
		read -rs -n 1 -p "$1"
	fi
	echo ""
}

is_bin_in_path() {
	# parameter(s): $1 -> cmd to test for ability to execute
	builtin type -P "$1" &>/dev/null
}

invert_boolean() {
	if [[ "$1" == 1 ]]; then
		echo 0
	elif [[ "$1" == 0 ]]; then
		echo 1
	else
		new_error_msg "ERROR: convert boolean"
	fi
}

get_script_dir() {
	# params: "$0" is from the orginal command line
	local s_dir
	s_dir=$(dirname "$(readlink -f "$0")")
	echo "$s_dir"
}

count_lines() {
	# param $1 - string containing n-lines to count
	echo -n "$1" | grep -c '^'
}

join_by_string() {
	# Join a list of items into a string
	# param $1 - the delimiter(s), can be multi character
	# param #2 .. strings to be joined
	local separator="$1"
	shift
	local first="$1"
	shift
	printf "%s" "$first" "${@/#/$separator}"
}

# ----- Configuration

# install_dir is where this file is installed
# assets_dir hold sound file and notification icon.
# var_dir is where notes and log are stored

configure() {
	echo "${lcy} ----- Configuration "
	echo "${lgn}bash version      ${lgb}$BASH_VERSION"
	echo "${lgn}program version:  ${lgb}$version"
	local conf_file="watch_time.cfg"
	invoke_cmd=$0
	install_dir=$(get_script_dir "${0}")
	echo "${lgn}invoke cmd:       ${lgb}$invoke_cmd"
	echo "${lgn}install dir:      ${lgb}$install_dir"
	# Note:
	#   ShellCheck is not able to include sourced files from paths that are determined at runtime.
	#   Hence need to work from the install directory.
	cd "$install_dir" || exit

	# --- Initial / Default Settings
	alarm_duration=10 # default duration of alarm in seconds
	clock_color=3
	sound_player="paplay" # default sound player
	mute_sound="false"
	mute_notification="false"

	# directory defaults
	var_dir="$install_dir/var"       # deault directory for log, notes
	assets_dir="$install_dir/assets" # default directory for icon and sound alarm
	flib_ini="${install_dir}/lib_ini.sh"

	# file defaults
	log="${install_dir}/var/log.txt"
	fdebug="${install_dir}/var/debug.txt"
	fnote="${install_dir}/var/notes.md" # default note file

	check_directories_and_files
	read_config $conf_file # if present, will override defaults

	echo "${lcy} ----- Settings "
	echo "${lgn}alarm duration:    " "${lgb}$alarm_duration"
	echo "${lgn}clock color:       " "${lgb}$clock_color"
	echo "${lgn}sound play cmd:    " "${lgb}$sound_player"
	if [[ $mute_sound == "false" ]]; then
		echo "${lgn}mute sound:        " "${lgb}$mute_sound"
	else
		echo "${lgn}mute sound:        " "${lrb}$mute_sound"
	fi

	if [[ $mute_notification == "false" ]]; then
		echo "${lgn}mute notification: " "${lgb}$mute_notification"
	else
		echo "${lgn}mute notification: " "${lrb}$mute_notification"
	fi

	echo "${lgn}var dir:           " "${lgb}$var_dir"
	echo "${lgn}assets dir:        " "${lgb}$assets_dir"
	# defaults files are provided
	icon="${assets_dir}/icon_alarm.png"
	sound="${assets_dir}/phone-incoming-call.oga"

	LOG="$var_dir/log.txt"
	DEBUG="$var_dir/debug.txt"
	NOTES="$var_dir/notes.md" # TODO
	NOTES="$fnote"
	echo "${lgn}notes file:        " "${lgb}$fnote"

	if [ ! -f "$LOG" ]; then touch "$LOG"; fi
	if [ ! -f "$DEBUG" ]; then touch "$DEBUG"; fi
	if [ ! -f "$NOTES" ]; then touch "$NOTES"; fi

	echo "" >"$fdebug" # reset debug file

	construct_sound_command
	pause ""
}

find_file() {
	# param $1: name of file to find
	# param $2: 0 do not source, 1 yes source

	if [ -f "${1}" ]; then
		echo "${lgn}$1      ${lgb}found"
		if [[ $2 = 1 ]]; then
			source "$1"
		fi
	else
		echo "${lgn}$1      ${lrb}not found"
	fi
}

check_directories_and_files() {
	# parameter(s): none
	echo "${lcy} ----- Checking files and directories "

	find_file "lib_clock.sh" "1"
	find_file "lib_time.sh" "1"
	find_file "lib_alarm.sh" "1"
	find_file "lib_ini.sh" "0"

	if [ ! -d "$var_dir" ]; then
		mkdir -p "$var_dir"
	fi

	if [ -z "$EDITOR" ]; then
		err_msg="WARNING: \$EDITOR is not defined in .bashrc\n\
         You will not be able to edit/view log and note files from this program"
		echo "${lgn}\$EDITOR is:       ${lrb}Not present"
	else
		echo "${lgn}\$EDITOR is:       ${lgb}$EDITOR"
		if is_bin_in_path "$EDITOR"; then
			echo "${lgn}$EDITOR              ${lgb}is on path"
		else
			echo "${lgn}$EDITOR              ${lgb}is NOT on path"
		fi
	fi
}

read_config() {
	# parameter(s): $1 -> name of config file
	local conf_file="$1"

	echo "${lcy} ----- Processing config file "
	if [[ -f $conf_file ]]; then
		echo "${lgn}config file:      ${lgb}found"
		process_conf "$conf_file"
	else
		echo "${lgn}config file:      ${lrb}** not found ** Using defaults"
	fi
}

process_conf() {
	# parameter(s): $1 -> name of config file
	# Process config file and replace default values as appropriate
	local cfile
	cfile="$1"
	# source "$flib_ini"
	source "lib_ini.sh"
	echo "${lgn}lib_ini.sh:       ${lgb}sourced"
	ini_loadfile "$cfile"
	local new_value

	new_value="$(ini_get_value "watch_time" "duration")"
	if [[ -n $new_value ]]; then alarm_duration=$new_value; fi

	new_value="$(ini_get_value "watch_time" "clock_color")"
	if [[ -n $new_value ]]; then clock_color=$new_value; fi

	new_value="$(ini_get_value "watch_time" "media_player")"
	if [[ -n $new_value ]]; then sound_player=$new_value; fi

	new_value="$(ini_get_value "watch_time" "mute_sound")"
	if [[ -n $new_value ]]; then mute_sound=$new_value; fi

	new_value="$(ini_get_value "watch_time" "mute_notification")"
	if [[ -n $new_value ]]; then mute_notification=$new_value; fi

	# Note: read does not expand variables from the config file
	# Hence need for eval when reading
	new_value="$(ini_get_value "watch_time" "var_dir")"
	if [[ -n $new_value ]]; then var_dir=$new_value; fi
	var_dir=$(eval echo "$var_dir")

	new_value="$(ini_get_value "watch_time" "assets_dir")"
	if [[ -n $new_value ]]; then assets_dir=$new_value; fi
	assets_dir=$(eval echo "$assets_dir")

	new_value="$(ini_get_value "watch_time" "notes_file")"
	if [[ -n $new_value ]]; then notes_file=$new_value; fi # TODO
	fnote=$(eval echo "$notes_file")
}

construct_sound_command() {
	# pattern for first work of text
	local re='^([[:alpha:]]+)([[:space:]].*)$'
	local cmd
	local opts
	cmd=$(echo "$sound_player" | awk '{print $1;}')
	# test for presence of player options
	opts=$(echo "$sound_player" | awk '{print $2;}')

	sound_play_cmd=""
	if ! is_bin_in_path "$cmd"; then
		echo "${lgn}Fail:                 ${lgb}player: $cmd is not available"
		return
	fi

	if [[ -z $opts ]]; then
		cmd_play_sound=("$cmd" "$sound")
	elif
		[[ $sound_player =~ $re ]]
	then
		cmd_play_sound=(" ${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$sound")
	else
		new_error_msg "WARNING: Problem playing sound"
	fi

	# "${cmd_play_sound[@]}"
	# sound_play_cmd="${cmd_play_sound[@]}"
	sound_play_cmd=$(join_by_string " " "${cmd_play_sound[@]}")
}

# ---- Screen Management

reset_line() {
	# first line is 0
	tput cup "$1" 0
	echo -ne "${reset}"
}

redraw() {
	clear_error_msg
	info_area_update 0
	clear
}

# ---- Status Messaging

secs2alarm_msg() {
	# seconds to alarm message
	# parameter(s): none
	if [[ $(is_alarm_running) == 1 ]]; then
		local secs
		secs="$(tm2alarm_secs)"
		echo "$secs"
	elif [[ $(is_alarm_destroyed) == 1 ]]; then
		echo "---"
	else
		echo "na"
	fi
}

enabled_msg() {
	case $alarm_enabled in
	0) echo "0 no" ;;
	1) echo "1 yes " ;;
	*) new_error_msg "ERROR: enabled_msg" ;;
	esac
}

status_msg() {
	case $alarm_state in
	0) echo "0 initial" ;;
	1) echo "1 running" ;;
	2) echo "2 expired" ;;
	3) echo "3 cancelled" ;;
	*) new_error_msg "ERROR: status msg" ;;
	esac
}

ring_msg() {
	local result
	result="$(is_alarm_ringing)"
	case $result in
	0) echo "0 off" ;;
	1) echo "1 on" ;;
	*)
		new_error_msg "ERROR: ring_msg"
		echo "$result error"
		;;
	esac
}

# ---- Error Management

display_error_area() {
	reset_line $err_line_start
	if [[ $alarm_enabled == 1 ]]; then
		echo -e "${ler}$err_msg${lnr}$cl2eol"
	else
		echo -e ""
	fi
}

clear_error_msg() {
	local start last
	start=$err_line_start
	last=$input_line_start
	err_msg=""

	for ((i = start; i < last; i++)); do
		reset_line "$i"
		echo -ne "${cl_ln}"
	done
}

new_error_msg() {
	# parameter(s): $1 - text of error message
	local msg
	msg="$1\n"
	err_msg+=$msg
}

# ---- Info Area Management

info_area_update() {
	# parameter(s): $1 new state

	# info area is shared by
	#   1. display_status,
	#   2. display menu
	#   3. new_note
	#   4. display_clock

	# if new state != old state then clear
	#   1. clear area
	#   2. flip the current state

	local new_state old_state
	new_state=$1
	old_state=$info_area_state

	if [[ $new_state -ne $old_state ]]; then
		clear_info_area
		info_area_state=$new_state
	fi
}

info_area_refresh() {
	local current
	current=$old_state
	clear_info_area
	info_area_update "$current"
}

clear_info_area() {
	# params: none
	local start itmcnt
	start=$info_line_start
	itmcnt=20
	echo -n -e "${reset}"
	tput cup start
	for ((i = start; i <= start + itmcnt; i++)); do
		reset_line "$i"
		echo -ne "${cl_ln}"
	done
}

display_info_area() {
	display_status
	display_menu
	display_clock
}

display_clock() {
	local tm
	if [[ $info_area_state == 4 ]]; then
		tm="$(date +'%H:%M')"
		reset_line $info_line_start
		show_clock "$tm" "$info_line_start" "$clock_color"

	elif [[ $info_area_state == 5 ]]; then
		if [[ $(is_alarm_running) == 1 ]]; then
			local secs_to_go
			secs_to_go=$(tm2alarm_secs)

			if [[ (($secs_to_go -lt 60)) ]]; then
				tm="$(tm2alarm_fmt 6)""   "
			elif [[ (($secs_to_go -lt 3600)) ]]; then
				tm="$(tm2alarm_fmt 7)"
			else
				tm="$(tm2alarm_fmt 2)"
			fi
			reset_line $info_line_start
			show_clock "$tm" "$info_line_start" "$clock_color"

		elif [[ $(is_alarm_expired) == 1 ]]; then
			tm="-$(tmFromalarm_fmt)"
			reset_line $info_line_start
			show_clock "$tm" "$info_line_start" "$clock_color"
		else
			info_area_state=0
			redraw
		fi
	fi
}

display_status() {
	local startln itmcnt
	startln=$info_line_start
	itmcnt=$((13 + 2))
	if [[ $info_area_state == 1 ]]; then
		# info_area_update 1
		echo -en "${reset}"
		reset_line $startln
		echo "${lgn}alarm id:         ${lgb}$alarm_id"
		# echo "${lgn}hr_alarm:         ${lgb}$hr_alarm"
		# echo "${lgn}mm_alarm:         ${lgb}$mm_alarm"
		# echo "${lgn}ss_alarm:         ${lgb}$ss_alarm"
		echo -e "${lgn}alarm message:    ${lgb}$alarm_msg${cl2eol}"
		echo "${lgn}--"
		echo "${lgn}alarm_enabled:    ${lgb}$(enabled_msg)" "$cl2eol"
		echo "${lgn}alarm_state:      ${lgb}$(status_msg)" "$cl2eol"
		echo "${lgn}ring state:       ${lgb}$(ring_msg)" "$cl2eol"
		echo "${lgn}--"
		echo "${lgn}seconds to alarm: ${lgb}$(secs2alarm_msg)${cl2eol}"
	fi
}

display_menu() {
	if [[ $info_area_state == 2 ]]; then
		reset_line $info_line_start
		echo "${lgb} o     ${lgn}enable/disable alarm${lnr} "
		echo "${lgb} a     ${lgn}set day alarm${lnr}"
		echo "${lgb} t     ${lgn}set timer alarm${lnr}"
		echo "${lgb} x     ${lgn}cancel alarm${lnr}"
		echo "${lgb} i,c   ${lgn}initialise / clear alarm${lnr}"
		echo "${lgb} m     ${lgn}edit alarm message${lnr}"
		echo "${lgb} n     ${lgn}new note${lnr}"
		echo "${lgb} N     ${lgn}edit note${lnr}"
		echo "${lgb} L     ${lgn}edit log${lnr}"
		echo "${lgb} S     ${lgn}show status${lnr}"
		echo "${lgb} M,h,? ${lgn}show menu${lnr}"
		echo "${lgb} T     ${lgn}test alarm${lnr}"
		echo "${lgb} r     ${lgn}clear and redraw${lnr}"
		echo "${lgb} C     ${lgn}large clock${lnr}"
		# echo "${lgb} D     ${lgn}large count down clock${lnr}"
		echo "${lgb} q     ${lgn}quit${lnr}"
	fi
}

edit_note() {
	$EDITOR "$fnote"
	redraw
}

edit_log() {
	$EDITOR "$log"
	redraw
}

process_menu_selection() {
	# read one character command
	tput civis
	read -r -s -t 0.2 -n 1 input

	case $input in
	o) alarm_enabled=$(invert_boolean "$alarm_enabled") ;;
	a) configure_alarm ;;
	t) configure_timer ;;
	m) enter_alarm_msg ;;
	x) destroy_alarm ;;
	i | c) initial_alarm ;;
	S) info_area_update 1 ;;
	n) new_note ;;
	N) edit_note ;;
	L) edit_log ;;
	r) redraw ;;
	M | h | '?') info_area_update 2 ;;
	T) test_alarm ;;
	C) info_area_update 4 ;;
	D) info_area_update 5 ;;
	q) exit ;;
		# TODO add menu and version
	esac
	tput civis
}

wipe_input() {
	local start last
	start=$input_line_start
	last=$info_line_start-1

	echo -n -e "${reset}"
	for ((i = start; i <= last; i++)); do
		reset_line "$i"
		echo -ne "${cl_ln}"
	done
}

enter_alarm_msg() {
	local input
	if [[ $(is_alarm_running) == 1 ]]; then
		tput cnorm
		reset_line $input_line_start
		echo -n "${lgd}Enter alarm message: ${lnr}"
		read -r input
		alarm_msg=$input
		wipe_input
		tput civis
	else
		new_error_msg "INFO: no alarm enabled or running"
	fi
}

new_note() {
	info_area_update 3
	tput cup $info_line_start
	tput cnorm

	echo "${ldm}Enter note: (press 'Enter' + 'ctl-d' to terminate input)"
	echo "${lnr}"
	local notes
	# to terminate editing: "CR + ^d"  or "^d + ^d"
	notes=$(</dev/stdin)
	{
		echo -e "\n# $(date +'%Y-%m-%d %a')\n"
		echo "$notes"
	} >>"$fnote"

	for ((i = info_line_start; i <= 20; i++)); do
		reset_line "$i"
		echo -ne "${cl_ln}{reset}"
	done
	tput cnorm
	tput civis
	info_area_update 0
}

# state management

initial_alarm() {
	clear_error_msg
	if [[ ($(is_alarm_destroyed) == 1) || ($(is_alarm_expired) == 1) ]]; then
		reset_alarm
		alarm_state=0
		redraw
	else
		new_error_msg "INFO: Can only Initialise from 'Cancel or Expired' state"
	fi
}

destroy_alarm() {
	# alarm can only be destroyed if in the 'running' state
	if [[ $(is_alarm_running) == 1 ]]; then
		local msg
		msg="alarm [$alarm_id] cancelled: $(date +'%Y-%m-%d %H:%M:%S')"
		echo "$msg" >>"$log"
		new_error_msg "INFO: $msg"
		reset_alarm
		alarm_state=3
	else
		new_error_msg "INFO: Can not cancel if alarm is not running"
	fi
}

check_expired_state() {
	# alarm can only be expired from 'running' state
	if [[ ($(is_alarm_running) == 1) && (($(tm2alarm_secs) -le 0)) ]]; then
		alarm_state=2
	fi
}

is_alarm_ringing() {
	# is the alarm 'ringing'?
	local duration t2a
	duration=$alarm_duration
	t2a=$(tm2alarm_secs)

	if [[ $(is_alarm_expired) == 1 ]]; then
		if ((t2a <= 0 && t2a > -duration)); then
			echo "1"
		else
			echo "0"
		fi
	else
		echo "0"
	fi
}

is_alarm_initial() {
	if [[ $alarm_state == 0 ]]; then
		echo "1"
	else
		echo "0"
	fi
}

is_alarm_running() {
	if [[ $alarm_state == 1 ]]; then
		echo "1"
	else
		echo "0"
	fi
}

is_alarm_expired() {
	if [[ $alarm_state == 2 ]]; then
		echo "1"
	else
		echo "0"
	fi
}

is_alarm_destroyed() {
	if [[ $alarm_state == 3 ]]; then
		echo "1"
	else
		echo "0"
	fi
}

# ---- Alarm handling

test_alarm() {
	if is_bin_in_path notify-send; then
		notify-send -u low -i "$icon" -t 4000 "test alarm" ""
	else
		new_error_msg "WARNING: notify-send not found"
	fi
	play_alarm
}

play_alarm() {
	# TODO understand why cmd_play_sound[@] does not work for ffplay with options
	#   "${cmd_play_sound[@]}"
	if [[ -n $sound_play_cmd ]]; then
		bash -c "$sound_play_cmd &>/dev/null "
	fi
}

sound_alarm() {
	# param: $1 - the message body
	if [[ $alarm_rung == 0 ]]; then
		local msg msg0 msg1
		msg="alarm [$alarm_id] expired:  "
		msg0="$msg $(date +'%Y-%m-%d %H:%M:%S')"
		msg1="$msg $(date +'%H:%M:%S')"
		start_expired_secs

		echo "$msg0" >>"$log"

		if [[ $mute_notification == "false" ]]; then
			if is_bin_in_path notify-send; then
				notify-send -u critical -i "$icon" "$msg1" "$1"
			else
				new_error_msg "WARNING: notify-send not found"
			fi
		fi

		if [[ $mute_sound == "false" ]]; then
			play_alarm
		fi
		alarm_rung=1
	fi
}

print_alarm_msg() {
	# params: $1 $2 message to be printed
	local msg="${1}${2}"
	reset_line 4
	if [[ $alarm_enabled == 0 ]]; then
		# printf "$cl_ln"
		echo -e "$cl_ln"
	else
		# printf $msg   #-- note: printf does not work for non-gui tty version
		echo "$msg"
	fi
}

process_state_change() {
	check_expired_state
	tput cup 3 0
	if [[ $alarm_enabled == 0 ]]; then
		echo "${lnr}${ldm}alarm disabled" "$cl2eol"
		print_alarm_msg

	elif [[ $(is_alarm_initial) == 1 ]]; then
		echo -e "${lnr}${ldm}no alarm set${cl2eol}"
		echo -e "$cl_ln"

	elif [[ $(is_alarm_destroyed) == 1 ]]; then
		echo -ne "${lnr}${ldm}cancelled" "$cl2eol"
		print_alarm_msg "${lnr}${ldm}${alarm_msg}${cl2eol}"

	elif [[ $(is_alarm_expired) == 0 ]]; then # RUNNING?
		# elif [[ $(is_alarm_running) == 1 ]]; then # RUNNING?
		local tm2a al_tm ats
		#       ats=$(get_alarm_dts_fmt)
		# al_tm=$(secs2date_fmt "$ats" 2)
		al_tm=$(get_alarm_dts_fmt)
		tm2a=$(tm2alarm_fmt "2")
		echo -e "${lnr}${ldm}next alarm at: ${lgn}${al_tm} ${lnd}in ${lgn}${tm2a}${cl2eol}"
		print_alarm_msg "${lnr}${ldm}$alarm_msg${cl2eol}"

		# Alarm has expired !
	elif [[ $(is_alarm_ringing) == 1 ]]; then
		echo -ne "${lrb}alarm on: xxxxxxxxxxxxx${cl2eol}"
		print_alarm_msg "${lrb}$alarm_msg${cl2eol}"
		sound_alarm "$alarm_msg"

		# Alarm has expired !
	elif [[ $(is_alarm_expired) == 1 ]]; then
		local t0 t1
		t0=$(tmFromalarm_fmt)
		t1=$(get_alarm_dts_fmt)
		printf "${lnr}${ldm}%s" "alarm expired @ $t1 ${lrb} ( $t0 )${cl2eol}"
		print_alarm_msg "${lnr}${ldm}${alarm_msg}${cl2eol}"

	else
		new_error_msg "ERROR: display alarm: no condition: $(alarm_msg)"
	fi
	tput civis
}

main() {
	configure "$0"
	clear
	tput init
	tput sgr0
	alarm_id=0 # initialise as an invalid alarm number
	# TODO -->
	# create_alarm "$1" "$2" "$3" "$4"

	while true; do
		tput civis
		reset_line 0
		echo "$cl2eol"
		printf "${ldm}%s\n" "$(date +'%Y %b %d - %a')"
		printf "${lgb}%s\n" "$(date +'%H:%M:%S')"
		process_state_change
		display_error_area
		display_info_area
		process_menu_selection # loop delay here!
	done
}

main "$@"

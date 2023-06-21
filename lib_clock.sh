#!/bin/bash

### Banner with color ###
# by rern

# 2023-04-17: adapted/simplified by David Rourke to display time only
#   - one line
#   - revised text digits
#   - both foreground and background color are the same.

# shellcheck disable=SC2001

# Each character is a 5 x 5 matrix.
# Each row is each matrix is joined togetherto form a larger row.
# All 'larger rows' are displayed
#   - one per lne.

n0=(
	'#####'
	'#   #'
	'#   #'
	'#   #'
	'#####'
)
n1=(
	'    #'
	'    #'
	'    #'
	'    #'
	'    #'
)
n2=(
	'#####'
	'    #'
	'#####'
	'#    '
	'#####'
)
n3=(
	'#####'
	'    #'
	'#####'
	'    #'
	'#####'
)
n4=(
	'#   #'
	'#   #'
	'#####'
	'    #'
	'    #'
)
n5=(
	'#####'
	'#    '
	'#####'
	'    #'
	'#####'
)
n6=(
	'#####'
	'#    '
	'#####'
	'#   #'
	'#####'
)
n7=(
	'#####'
	'    #'
	'    #'
	'    #'
	'    #'
)
n8=(
	'#####'
	'#   #'
	'#####'
	'#   #'
	'#####'
)
n9=(
	'#####'
	'#   #'
	'#####'
	'    #'
	'#####'
)
colon=(
	'     '
	'  #  '
	'     '
	'  #  '
	'     '
)
space=(
	'     '
	'     '
	'     '
	'     '
	'     '
)
dash=(
	'     '
	'     '
	'#####'
	'     '
	'     '
)
parenthesesL=(
	'  #  '
	' #   '
	' #   '
	' #   '
	'  #  '
)
parenthesesR=(
	'  #  '
	'   # '
	'   # '
	'   # '
	'  #  '
)
bracketL=(
	' ### '
	' #   '
	' #   '
	' #   '
	' ### '
)
bracketR=(
	' ### '
	'   # '
	'   # '
	'   # '
	' ### '
)




# Globals
banner=''
col_clk=0

array2banner() {
	# params $@ text of time to display
	local string="${@^^}" # convert to uppercase
	local arrayline0 arrayline1 arrayline2 arrayline3 arrayline4 char line0 line1 line2 line3 line4

	arrayline0=()
	arrayline1=()
	arrayline2=()
	arrayline3=()
	arrayline4=()

	# for each digit in string, get matrix representation
	for ((i = 0; i < ${#string}; i++)); do
		# array element to character
		char=${string:i:1}
		# character to substitue
		case "$char" in
		[0-9]) char="n$char" ;;
		':') char='colon' ;;
        ' ') char='space' ;;
        '-') char='dash' ;;
        '(') char='parenthesesL' ;;
        ')') char='parenthesesR' ;;
        '[') char='bracketL' ;;
        ']') char='bracketR' ;;
		esac
		arrayline0[i]="${char}[0]"
		arrayline1[i]="${char}[1]"
		arrayline2[i]="${char}[2]"
		arrayline3[i]="${char}[3]"
		arrayline4[i]="${char}[4]"
	done

	# array of lines to lines of value sequence - with '!'indirect reference
	# arrayline0=(A[0] B[0] C[0] ...) -> line0="$A[0] $B[0] $C[0] ... "
	line0='' line1='' line2='' line3='' line4=''
	for ((i = 0; i < ${#string}; i++)); do
		line0+=" ${!arrayline0[i]}"
		line1+=" ${!arrayline1[i]}"
		line2+=" ${!arrayline2[i]}"
		line3+=" ${!arrayline3[i]}"
		line4+=" ${!arrayline4[i]}"
	done
	# tput cup 5 10 # DEBUG
	# echo "$line0" >&2
	# echo "$line1" >&2
	# echo "$line2" >&2
	# echo "$line3" >&2
	# echo "$line4" >&2
	# banner - append all lines
	# banner is Global!
	banner=$banner"\n$line0\n$line1\n$line2\n$line3\n$line4\n"
}
# break string to array of each banner line
string2array() {
	local tm=$1
	array2banner "$tm"
	time_out=$(echo "$banner" | sed -e 's/#\+/\\e[38;5;'"$col_clk"'m\\e[48;5;'"$col_clk"'m&/g' -e 's/#\+/&\\e[0m/g')
	echo -e "$time_out"
}

show_clock() {
	# param $1: time to display
	# param $2: begin row for display
	# param $3: color of text and background color
	local tm=$1
	local clock_start_row=$2
	col_clk=$3
	tput civis
	# tm="$(date +'%H:%M')"
	# echo "$tm"
	out=$(string2array "$tm")
	tput cup "$clock_start_row"
	# echo "$2"
	echo "$out"
}

test() {
	clear
	while true; do
		tm="$(date +'%H:%M')"
		display_clock "$tm" 14 3
		sleep 1
	done
}
# test

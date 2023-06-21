

declare -A config


ini_loadfile () {
    # parameter(s): $1 -> name of file to load
    local cur_section=""
    local cur_key=""
    local cur_val=""
    IFS=
    while read -r line; do
        new_section=$(_ini_get_section "$line")
        # got a new section
        if [[ -n "$new_section" ]]; then
            cur_section=$new_section
        # not a section, try a key value
        else
            val=$(_ini_get_key_value "$line")
            # trim the leading and trailing spaces as well
            cur_key=$(echo "$val" | cut -f1 -d'=' | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//') 
            cur_val=$(echo "$val" | cut -f2 -d'=' | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//')

        if [[ -n "$cur_key" ]]; then
            # section + key is the associative in bash array, the field seperator is space
            config[${cur_section}:${cur_key}]=$cur_val
        fi
    fi
    done <"$1"
}

_ini_get_section () {
    # Note: '[' must start at beginning of line
    if [[ "$1" =~ ^(\[)(.*)(\])$ ]]; 
    then 
        echo "${BASH_REMATCH[2]}" ; 
    else 
        echo ""; 
    fi
}

_ini_get_key_value () {
    # Note: leading spaces allowed
    if [[ "$1" =~ ^([^=]+)=([^=]+)$ ]]; 
    then 
        echo "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"; 
    else 
        echo ""
    fi
}

ini_printdb () {
    for key in "${!config[@]}"
    do
        # split the associative key into section and key
        local section; local xkey; local value;
        section=$(echo "$key" | cut -f1 -d ':')
        xkey=$(echo "$key" | cut -f2 -d ':')
        value=${config[$key]}
        printf "%-15s %15s = %-15s\n" "$section" "$xkey" "$value"
    done
}

ini_get_value () {
    local section=$1
    local key=$2
    echo "${config[$section:$key]}"
}

# general method. Does not depennd upon format key 'section:key' in config
# note use of local -n to pass in associative array.
list_all_pairs () {
    # parameter(s): $1 name of associative array
    local -n ary=$1
    for key in "${!ary[@]}"
    do
      printf "key: %-25s value: %-15s\n" "$key" "${ary[$key]}"
    done
}

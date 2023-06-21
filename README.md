<!--toc:start-->

# watch_time.sh
  ## Objectives
  ## Usage
  ## Configuration
  ## Recommended Installation
    ### Location
    ### Access
    ### Resource Files
      #### var subdirectory
      #### assets subdirectory
      #### External Program
  ## Complet Shell configuration changes (eg. .bashrc)
  ## How To Use 
  ## Future Enhancements

<!--toc:end-->


# watch_time.sh

## Objectives

1. To monitor time and optionally set an event trigger that 'sounds' an alarm

2. To expedite all interaction in as few keystrokes as possible.

   - no 'yes/no' dialogues or confirmation checks.

3. Maintain a notes/jottings file

The alarm trigger can be set in two ways:

    1. As an absolute time of day.
    2. As an offset from the current moment.

The term 'day-alarm' refers to the absolute time of day alarm

    - eg. 11 03 04 referring to 11:0:04 am

The term 'timer-alarm' refers to the countdown timer.

    - eg. entering 1 3 25 referring to 1 hour, 3 min, 25 seconds from now.

Both the 'day-alarm' and the 'timer-alarm' resolve to an absolute time of day.

    - Once set, both are refered to as 'alarm time'

Times are specified in 24-hours format as hh mm ss format.

    - there is no concept of a next day - only the current day.
    - there is no 'date' associated with an alarm-time
        - just a 24 hour alarm-time.
    - Alarm time is a valid for the current calendar day.

If 'alarm time' lags 'actual' time on a 24 hour clock,

    - it will be considered to be expired for the current day
    - it will reactivate at the stroke of midnight  (unless cancelled).

An alarm cannot be set for midnight which has time 00:00:00.

    - 00:00:00 is used to designate 'no-time' or 'invalid-time'

Alarm events (create, expired, destroyed) are logged to the var/log.txt file.

    - This file must be present and is created if not present.
    - All alarms are assigned an 'id' when created.
    - This 'id' is generated form the highest alarm alarm number in the var/log.txt file.

## Usage

    $ watch_time [< hh> [<mm> [<ss> [<description>] ] ]   ]
        - examples
            $ watch_time
            $ watch_time 10                         # hour only
            $ watch_time 10 31                      # hour and minutes
            $ watch_time 10 31 43                   # hour minute seconds
            $ watch_time 10 31 00 'coffee time'     # hour minute seconds message

    - The command line options can only specify a day alarm, not a timer
    - The day alarm can also be set (more conveniently) within program -- press 'a'
    - The timer is set from within the running program -- press 't'
    - The program is keystroke driven. Viewing the menu (SHIFT-M) is for display only (memory jog)

While program is running, these key presses are available:

    o         to enable / disable the alarm (on / off)
    a         configure and set day alarm
    t         configure and set count-down timer
    x         cancel alarm
    i         initialise new alarm
    m         enter / edit message for alarm
    n         create a new new note
    N         view/edit note file using an external editor
    L         view/edit log file  using an external editor
    s         show status
    M,h,?     show menu (keystroke actions) (not necessary - Memory jog only)
    r or c    redraw and reset the screen
    q         quit the program

## Configuration

    - Default values are provided in the source code.
    - A configuration file ('watch_time.cfg') in available in the install directory.

## Recommended Installation

### Location

( Assuming '.bashrc' as the shell configuration file)

Linux Installation (using /home/david/src/bash/watch_time) directory as an example

    0. Create an instal directory

    1. Put the source files in an install directory and unzip

        Install Directoy should look like this:

        david@arch ~/src/bash/watch_time]$ tree
        .
        ├── assets
        │   ├── icon_alarm.png
        │   ├── phone-incoming-call.oga
        │   └── suspend-error.oga
        ├── lib_ini.sh
        ├── var
        │   ├── log.txt
        │   ├── notes.md
        │   └── notes.txt
        ├── watch_time.cfg
        ├── watch_time.d2
        ├── watch_time.sh
        └── watch_time.svg

        3 directories, 11 files

### Access

    1. Ensure that the script 'watch_time.sh' is executable

        $ chmod +x watch_time.sh

    2. Ensure that the directory is on the execution path (edit .bashrc)

    3. Option: Create a convenient alias

    ... edit .bashrc or equivalent
    export PATH=/home/david/src/bash/watch_time:$PATH
    alias wt="watch_time.sh"
    ...

### Resource Files

#### var subdirectory

The first time the program runs - it will create a 'var' sub-directory
off the install directory to hold ouput from the Program

    a. a log file
    b. a note file

    examples: /home/david/scripts/log.txt
                /home/david/scripts/note.txt

#### assets subdirectory

The assets subdirectory contains two file
1. A sound file for the alarm
2. An icon for the notify message

The sound file needs to be located in "<install-directory>/assets

- the default configuration assumes that pulse-audio and paplayer are installed.

#### External Program

1. The linux program 'send-notify' should be installed.

    - It usually included by default during system was set up.

2. A text editor should be installed and configured.

    - this enables the viewing/editing of the log and note file
    - ... from within the program.

 3. Access to the EDITOR is defined in the shell configuration file

    Common Examples:
        export EDITOR=vim
        or
        export EDITOR=nano

## Complete Shell configuration changes (eg. .bashrc)

    example:

        export EDITOR=vim
        export PATH=/home/david/src/bash/watch_time:$PATH
        alias wt="watch_time.sh"

## How To Use 

1. Start the program with the alias wt (if the alias was set)

2. Set an alarm time:

    a. an offset alarm by pressing 't'
    b. a day alarm by pressing 'a'

3. When alarm is triggered:

    - a red bar of 'xxx's appears for 'duration' seconds
        - (default duration is 10 seconds)
    - a system notification is sent
    - a sound file is played

4. The display uses six main lines as follows:

    line 1: blank
    line 2: date line: YYYYY MM DD Day
    line 3: time line: hh:mm:sec
    line 4: alarm status and info
    line 5: alarm message
    line 6: error, warning, info message

    Other areas of screen are used for inputs and information.

5. Numeric entry is very forgiving:

   - a blank entry has the value 0.
   - all letters and leading zeros are filtered out
   - example: entry we002gx3b -> 23

6. Example

   # start the program with no parameters

   $ watch_time.sh

   # Press letter 't' and follows prompts for input.

## Future Enhancements

1. enable multiple alarms
2. read presets from file
3. notifications for upcoming triggers
4. a stop watch to log activities
5. read future presents (beyond the current day)

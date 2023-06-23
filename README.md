# watch_time.sh

## Objectives

1. To monitor time and optionally set an event trigger that 'sounds' an alarm

2. To expedite all interaction in as few keystrokes as possible.

   - that is, there are no 'yes/no' dialogues or confirmation checks.

3. Maintain a notes/jottings file

The alarm trigger can be set in two ways:

    1. As an absolute time of day. ('day alarm')
    2. As an offset from the current moment. ('timer alarm')

## Terms

The term 'day alarm' refers to the absolute time of day alarm

    - e.g. 11 03 04 referring to 11:0:04 am

The term 'timer alarm' refers to the countdown timer.

    - e.g. entering 1 3 25 referring to 1 hour, 3 min, 25 seconds from now.

The 'day-alarm' and the 'timer-alarm' both resolve to an absolute time of day for a particular date.

    - Once set, both are referred to as 'alarm time'
    - Setting a 'day alarm' can only be done for the current date.
    - Setting a 'timer alarm' can set the alarm for up to one hundred hours in the future.

Times are specified in 24-hours format as 'hh mm ss' format.

If 'alarm time' lags 'actual' time on a 24 hour clock,

    - it will be considered to be expired for the current day

Alarm events (create, expired, destroyed) are logged to the 'var/log.txt' file.

    - This file must be present and is created if not present.
    - All alarms are assigned an 'id' when created.
    - This 'id' is generated form the highest alarm alarm number in the var/log.txt file.

## Usage

    $ watch_time [< hh> [<mm> [<ss> [<description>]]]]
        - examples
            $ watch_time
            $ watch_time 10                         # hour only
            $ watch_time 10 31                      # hour and minutes
            $ watch_time 10 31 43                   # hour minute seconds
            $ watch_time 10 31 00 'coffee time'     # hour minute seconds message

    - The command line options can specify a 'day alarm' but not a 'timer alarm'
    - More practically, the 'day alarm' can also be set  within program -- press 'a'
    - The 'timer alarm' is set from within the running program -- press 't'
    - The program is keystroke driven. Viewing the menu (SHIFT-M) is for display only (memory jog)

While the program is running, these key presses are available:

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
    r or c    redraw/clear screen  and reset the screen
    q         quit the program

## Configuration

    - Default values are provided in the source code.
    - A configuration file ('watch_time.cfg') in available in the install directory.

## Recommended Installation

### Location

( Assuming '.bashrc' as the terminal shell configuration file)

Linux Installation (using /home/david/src/bash/watch_time) directory as an example

0. Create an install directory

1. Put the source files in an install directory

Install Directoy should look like this:

    .
    ├──  assets
    │  ├──  icon_alarm.png
    │  ├──  phone-incoming-call.oga
    │  └──  suspend-error.oga
    ├──  var
    │  ├──  debug.txt
    │  ├──  log.txt
    │  └──  notes.md
    ├──  CHANGE_LOG
    ├──  GIT_MSG
    ├──  lib_alarm.sh
    ├──  lib_clock.sh
    ├──  lib_ini.sh
    ├──  lib_time.sh
    ├──  README.md
    ├──  watch_time.cfg
    ├──  watch_time.d2
    ├──  watch_time.sh
    └──  watch_time.svg


### Execution of Script

1. Ensure that the script 'watch_time.sh' is executable

    $ chmod +x watch_time.sh

2. Ensure that the directory is on the execution path (edit .bashrc)

3. Option: Create a convenient alias

... 
    edit .bashrc or equivalent
    export PATH=/home/david/src/bash/watch_time:$PATH
    alias wt="watch_time.sh"
...

or place a symbolic link in '$HOME/.local/bin'

### Resource Files

#### var subdirectory

The first time the program runs - it will create a 'var' sub-directory
off the install directory to hold ouput from the Program

    a. a log file
    b. a note file

    examples:   /home/david/scripts/log.txt
                /home/david/scripts/note.txt

#### assets subdirectory

The assets subdirectory contains two file

1. A sound file for the alarm
2. An icon for the notify message

The sound file needs to be located in "<install-directory>/assets"

- the default configuration assumes that pulse-audio and paplayer are installed.

#### External Program

1. The Linux program 'send-notify' should be installed.

    - It usually included by default during system was set up.

2. A text editor should be installed and configured.

    - this enables the viewing/editing of the log and note file from within the program.

 3. Access to the EDITOR is defined in the shell configuration file

    - Common Examples:

```
        export EDITOR=vim
        export EDITOR=nano
```

## Complete Shell configuration changes (eg. .bashrc)

Example

    export EDITOR=vim
    export PATH=/home/david/src/bash/watch_time:$PATH
    alias wt="watch_time.sh"

## How To Use 

1. Start the program with the alias 'wt' (if the alias was set)

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

```
   # start the program with no parameters
   $ watch_time.sh
   # Press letter 't' and follows prompts for input.
```

## Future Enhancements

1. enable multiple alarms
2. read presets from file
3. notifications for upcoming triggers
4. a stop watch to log activities

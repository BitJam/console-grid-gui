. $LIB_DIR/lib-screen.sh
. $LIB_DIR/lib-grid.sh

: ${EDITOR:=nano}

: ${LIVE_MP:=/live/boot-dev}

for ed in nano; do
    which $ed &>/dev/null && continue
    EDITOR=$ed
    break
done

export TEXTDOMAIN="console-lib-menu"


PARENT_NAME=$(basename $(ps -o comm= $PPID))
HELP_PAGE=$ME

SUDO=sudo
[ $UID -eq 0 ] && SUDO=

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
redraw() {
    screen_draw
    grid_activate
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
restart() {
    local save_sel=$GRID_SEL
    local save_def=$GRID_DEFAULT_SEL
    init
    GRID_SEL=$save_sel
    GRID_DEFAULT_SEL=$save_def
    clear
    redraw
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
set_title_2() {
    if under_main_cc; then
        screen_set title2=$"<Enter> select option, <q> return to Main, <h> help"
    else
        screen_set title2=$"<Enter> select option, <q> quit, <h> help"
    fi
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
entry() {
    local lab=$1  prog=$2
    if [ -n "$prog" ]; then
        which "$prog"  &>/dev/null || return
    fi
    echo "$lab"
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
under_main_cc() {
    [ "$PARENT_MENU" = 'main_cc' ]
    return $?
}

in_main_cc() {
    [ "$THIS_MENU" = 'main_cc' ]
    return $?
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
return_to_main_entry() {
    under_main_cc && printf "${cyan}%s\n" $"Return to main menu"
}

back_to_main_entry() {
    centered_lab "$cyan%s" $"Return to main menu"
}

centered_lab() {
    local fmt=$1 ; shift
    local lab=$(printf "$fmt" "$@")
    local len=$(str_len "$lab")
    local pad=$(((MENU_WIDTH - len) / 2))
    printf "\e[${pad}C$lab"
}
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
return_to_main() {
    [ "$1" = $"Return to main menu" ] || return 1
    select_menu "$PARENT_MENU" "$MAIN_CC_$SEL"
    return 0
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
lpad_word() {
    local width=$1  word=$2
    local pad=$((width - ${#word}))
    [ $pad -le 0 ] && pad=0
    printf "\e[${pad}C"
    printf "%s" "$word"
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
#  cmd_entry() {
#      local  cmd=$1  blurb=$2  cwidth=${3:-20}
#      cwidth=$((cwidth - 1))
#      printf "%s: %s\n" "$(lpad_word $cwidth "." "$cmd")" "$blurb"
#  }

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
add_cmd() {
    local cmd=$1  blurb=$2  real_cmd=${3:-$1}
    [ -z "$cmd" ] && return

    real_cmd=${real_cmd%% *}

    if ! which $real_cmd &>/dev/null; then
        echo "command not found: $real_cmd" >> $log_file
        return
    fi

    #cmd=$(basename $cmd)
    local cwidth=${#cmd}
    [ $CMD_WIDTH -lt $cwidth ] && CMD_WIDTH=$cwidth
    local mwidth=$((cwidth + $(str_len "$blurb") + 2))

    [ $MENU_WIDTH -lt $mwidth ] && MENU_WIDTH=$mwidth
    MENU_LIST="${MENU_LIST}cmd $cmd&$blurb\n"
}

add_view() { _add_file "${yellow}View$white" "$@"; }
add_edit() { _add_file "${cyan}Edit$white"   "$@"; }
add_file() { _add_file ""     "$@"; }

_add_file() {
    local type=$1  blurb=$2  file=$3
    [ -z "$file" ] && return

    if ! test -e $file; then
        echo "File not found: $file" >> $log_file
        return
    fi

    base=$(basename $file)
    local cwidth=${#base}
    [ $CMD_WIDTH -lt $cwidth ] && CMD_WIDTH=$cwidth
    [ -n "$type" ] && blurb="$type $blurb"
    local mwidth=$((cwidth + $(str_len "$blurb") + 2))

    [ $MENU_WIDTH -lt $mwidth ] && MENU_WIDTH=$mwidth
    MENU_LIST="${MENU_LIST}file $base&$blurb\n"
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
start_menu_list() {
    MENU_WIDTH=0
    CMD_WIDTH=0
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
end_menu_list() {
    local type line cmd blurb
    while read type line; do
        cmd=${line%%&*}
        blurb=${line#*&}

        printf "$yellow%s$white: %s\n" "$(lpad_word $((CMD_WIDTH + 1)) "$cmd")" "$blurb"
    done <<Show_cmds
$(echo -e "$MENU_LIST")
Show_cmds
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
run_cmd() {
    local pause sudo exec check opts reset need_gpm stop_gpm

    local orig_size=$(stty size)

    clear
    if [ -z "${1##-*}" ]; then
        opts=$1 ; shift
        [ -z "${opts##-*p*}" ] && pause=true
        [ -z "${opts##-*s*}" ] && sudo=$SUDO
        [ -z "${opts##-*c*}" ] && check=true
        [ -z "${opts##-*r*}" ] && reset=true
        [ -z "${opts##-*g*}" ] && need_gpm=true
        [ -z "${opts##-*e*}" ] && exec='exec '
    fi

    restore_tty

    if [ "$need_gpm" ] && in_vt && ! pgrep --full /usr/bin/gpm &>/dev/null; then
        printf "$cyan%s$nc\n" "$SUDO service gpm start"
        $SUDO service gpm start
        sleep 2
        stop_gpm=true
    fi

    local pre=$exec$sudo
    echo "$pre${pre:+ }$*" >> $cmd_file
    printf "\e[0;0H$cyan$exec$sudo $*$nc\n"

    if [ "$check" ]; then
        local xxx
        read     -t .01 xxx
        read -N1 -t .01 xxx
        read -N1 -t .01 xxx
        read -N1 -t .01 xxx
        printf $"Are you SURE you want to %s (y/N) " "$1"
        local ans
        read ans
        echo
        case $ans in
            [Yy]*) ;;
                *) hide_tty ; redraw; return ;;
        esac
    fi

    [ "$exec" ] && exec $sudo "$@" 2>&1

    $sudo "$@" 2>&1
    local ret=$?

    [ "$stop_gpm" ] && $SUDO service gpm stop

    [ $ret -eq 0 ] || pause=true
    [ "$pause" ] && pause

    hide_tty

    set_window_title "$THE_MENU_TITLE"
    [ "$(stty size)" != "$orig_size" ] && reset=true

    if [ "$reset" ]; then
        re_init
        reset_menu
    fi

    redraw
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
edit_file() {
    local sudo opts
    clear
    if [ -z "${1##-*}" ]; then
        opts=$1 ; shift
        [ -z "${opts##-*s*}" ] && sudo=$SUDO
    fi

    local file=$1

    if ! sudo test -e $file; then
        db_msg $"File not found %s" "$(dbq "$file")"
        return
    fi

    if ! sudo test -w $file; then
        db_msg $"Cannot write to file %s" "$(dbq "$file")"
        return
    fi

    restore_tty

    local cmd="$EDITOR $file"
    echo "$cmd" >> $cmd_file
    printf "\e[0;0H$yellow$exec$cmd$nc\n"

    $sudo bash -c "$cmd" 2>&1

   hide_tty
   redraw
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
view_cmd() {

    local opts sudo
    clear
    if [ -z "${1##-*}" ]; then
        opts=$1 ; shift
        [ -z "${opts##-*s*}" ] && sudo=$SUDO
    fi

    restore_tty

    echo "$sudo${sudo:+ }$*" >> $cmd_file
    printf "\e[0;0H$yellow$exec$sudo $*$nc\n"

    local lines=$($sudo "$@" | wc -l | cut -d" " -f1)
    local height=$(screen_height)
    if [ $lines -lt $((height - 5)) ]; then
        $sudo "$@"
        pause

    else
        warn_of_less 'output'

        $sudo "$@" | less -RS
    fi

    hide_tty
    redraw
}

warn_of_less() {
    local type=$1
    echo
    msg $"There are too many %s lines to fit on the screen all at once."  "$type"
    msg $"Therefore the %s will be sent to the 'less' program."           "$type"
    msg $"You can scroll the %s with the arrow keys, <page-up>, and <page-down>." "$type"
    msg $"Use <Home> to go to the beginning and <End> to go to the end"
    msg $"Press 'q' when you are done.  Use 'h' for help and many more commands."
    echo
    pause
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
msg() {
    local fmt=$1 ; shift
    printf "$cyan$fmt$nc_co\n" "$@"
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
view_file() {
    local opts sudo

    if [ -z "${1##-*}" ]; then
        opts=$1 ; shift
        [ -z "${opts##-*s*}" ] && sudo=$SUDO
    fi

    local file=$1

    restore_tty

    local lines=$(wc -l "$file" | cut -d" " -f1)
    local height=$(screen_height)
    if [ $lines -lt $((height - 5)) ]; then

        echo "less -RSE $file" >> $cmd_file
        printf "\e[0;0H${yellow}less -RSE $file$nc\n"
        less -RSE "$file"
        pause

    else

        printf "less -RS $file" >> $cmd_file
        printf "\e[0;0H${yellow}less -RS $file$nc\n"
        warn_of_less 'file'
        less -RS "$file"
    fi

   hide_tty
   redraw
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
is_cmd() { which "$1" &>/dev/null ; return $? ; }

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
pause() {
    local xxx
    read     -t .01 xxx
    read -N1 -t .01 xxx
    read -N1 -t .01 xxx
    read -N1 -t .01 xxx
    echo -n "${cyan}Press <Enter> to continue$nc"
    read -s xxx
    echo
}

#------------------------------------------------------------------------------
# Very fast.  Just set some variables for later use
#------------------------------------------------------------------------------
new_menu() {
    local name=$1  title=$2  menu=$3
    eval MENU_TITLE_$name=\$title
    eval MENU_MENU_$name=\$menu
    eval MENU_NEW_$name=true
}

#------------------------------------------------------------------------------
# Only create the menus when needed
#------------------------------------------------------------------------------
select_menu() {
    local name=$1  sel=$2

    PARENT_MENU=$THIS_MENU
    THIS_MENU=$name

    local new title
    eval new=\$MENU_NEW_$name
    eval title=\$MENU_TITLE_$name
    THE_MENU_TITLE=$title
    set_window_title "$title"

    if [ "$new" ]; then
        eval title=\$MENU_TITLE_$name
        grid_read_new $name "$(eval \$MENU_MENU_$name)"
        grid_narrow y=5 title="$title"
        grid_center_x
        grid_fill_y 15
        grid_finalize

        eval MENU_NEW_$name=
    fi

    grid_activate $name
    [ "$sel" ] && grid_goto $sel
    clear
    redraw
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
reset_menu() {
    local this_menu=$THIS_MENU
    local THIS_MENU=$PARENT_MENU
    select_menu $this_menu
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
get_time() { cut -d" " -f22 /proc/self/stat ;}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
delta_time() {
    get_seconds $(($(get_time) - $1))
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
get_seconds() {
    local dt=${1:-$(get_time)}
    printf "%03d" $dt | sed -r 's/(..)$/.\1/'
}


#------------------------------------------------------------------------------
# Returns true on a live antiX/MX system, returns false otherwise.  May work
# correctly on other live systems but has not been tested.
#------------------------------------------------------------------------------
its_alive() {
    # return 0
    local root_fstype=$(df -PT / | tail -n1 | awk '{print $2}')
    case $root_fstype in
        aufs|overlay) return 0 ;;
                   *) return 1 ;;
    esac
}

#------------------------------------------------------------------------------
# Return true if running live and we can write to $LIVE_MP (/live/boot-dev)
# FIXME: Can this be easily fooled by "toram"?
#------------------------------------------------------------------------------
its_alive_usb() {
    its_alive             || return 1
    [ "$ITS_A_LIVE_USB" ] && return 0
    local dir=$LIVE_MP
    test -d $dir         || return 1
    is_writable "$dir"   || return 1
    ITS_A_LIVE_USB=true
    return 0
}

#------------------------------------------------------------------------------
# Test if a directory is writable by making a temporary file in it.  May not
# be elegant but it is pretty darned robust IMO.
#------------------------------------------------------------------------------
is_writable() {
    local dir=$1
    test -d "$dir" || fatal "Directory %s does not exist" "$dir"
    local temp=$(mktemp -p $dir 2> /dev/null) || return 1
    test -f "$temp" || return 1
    rm -f "$temp"
    return 0
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
distro_version() {
    local version  file=/etc/antix-version
    test -r $file && read version 2>/dev/null <$file
    version=$(echo "$version" | cut -d" " -f1,2)
    its_alive && version="$version Live"
    echo "$version"
}

screen_height() { stty size | cut -d" " -f1; }
screen_width()  { stty size | cut -d" " -f2; }

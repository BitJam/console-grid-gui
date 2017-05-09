. $LIB_DIR/lib-screen.sh
. $LIB_DIR/lib-grid.sh

PARENT_NAME=$(basename $(ps -o comm= $PPID))
echo "PPID: $PPID"
HELP_PAGE=$ME

SUDO=sudo
[ $UID -eq 0 ] && SUDO=

redraw() {
    screen_draw
    grid_activate
}

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
    [ "$PARENT_NAME" = "cli-cc" ]
    return $?
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
return_to_main_entry() {
    under_main_cc && echo "${cyan}Return to main menu"
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
exit_to_main() {
    [ "$1" = "Return to main menu" ] && exit 0
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
    
    : ${CWIDTH:=0}

    if ! which $real_cmd &>/dev/null; then
        echo "command not found: $real_cmd" >> $log_file
        return
    fi

    local cwidth=${#cmd}
    [ $CWIDTH -lt $cwidth ] && CWIDTH=$cwidth
    CMD_LIST="$CMD_LIST$cmd $blurb\n"
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
show_cmds() {
    local cmd  blurb
    while read cmd blurb; do
        printf "%s: %s\n" "$(lpad_word $((CWIDTH + 1)) "$cmd")" "$blurb"
    done <<Show_cmds
$(echo -e "$CMD_LIST")
Show_cmds
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
run_cmd() {
    local pause sudo exec check opts

    clear
    if [ -z "${1##-*}" ]; then
        opts=$1 ; shift
        [ -z "${opts##-*p*}" ] && pause=true
        [ -z "${opts##-*s*}" ] && sudo=$SUDO
        [ -z "${opts##-*c*}" ] && check=true 
        [ -z "${opts##-*e*}" ] && exec="exec "
    fi

    clear
    restore_tty

    # echo "opts  $opts"
    # echo "pause $pause"
    # echo "exec  $exec"
    # echo "sudo  $sudo"
    # echo "check $check"

    if [ "$check" ]; then
        printf "Are you SURE you want to %s (y/N) " "$1"
        local ans
        read ans
        echo
        case $ans in
            [Yy]*) ;;
                *) clear; hide_tty ; redraw; return ;;
        esac
    fi

    printf "\e[0;0H$cyan$exec$sudo $*$nc\n"

    if [ "$exec" ]; then
        exec $sudo "$@" 2>&1
    else
        ($sudo bash -c "$*" 2>&1)&
        local pid=$!
        wait $pid
    fi

    [ "$pause" ] && pause

   clear
   hide_tty
   redraw
}

is_cmd() { which "$1" &>/dev/null ; return $? ; }

pause() {
    local xxx
    echo -n "${cyan}Press <Enter> to continue$nc"
    read -s xxx
}

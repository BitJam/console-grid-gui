. $LIB_DIR/lib-screen.sh
. $LIB_DIR/lib-grid.sh

: ${EDITOR:=nano}

for ed in nano; do
    which $ed &>/dev/null && continue
    EDITOR=$ed
    break
done


PARENT_NAME=$(basename $(ps -o comm= $PPID))
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
    [ "$PARENT_MENU" = "main_cc" ]
    return $?
}

in_main_cc() {
    [ "$THIS_MENU" = "main_cc" ]
    return $?
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
return_to_main_entry() {
    under_main_cc && echo "${cyan}Return to main menu"
}

back_to_main_entry() {
    centered_lab "${cyan}Return to main menu"
}

centered_lab() {
    local lab=$1
    local len=$(str_len "$lab")
    local pad=$(((MENU_WIDTH - len) / 2))
    printf "\e[${pad}C$lab"
}
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
return_to_main() {
    [ "$1" = "Return to main menu" ] || return 1
    select_menu $PARENT_MENU
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

    if ! which $real_cmd &>/dev/null; then
        echo "command not found: $real_cmd" >> $log_file
        return
    fi

    cmd=$(basename $cmd)
    local cwidth=${#cmd}
    [ $CMD_WIDTH -lt $cwidth ] && CMD_WIDTH=$cwidth
    local mwidth=$((cwidth + $(str_len "$blurb") + 2))

    [ $MENU_WIDTH -lt $mwidth ] && MENU_WIDTH=$mwidth
    MENU_LIST="${MENU_LIST}cmd $cmd $blurb\n"
}

add_file() {
    local blurb=$1 file=$2
    [ -z "$file" ] && return

    if ! test -e $file; then
        echo "File not found: $file" >> $log_file
        return
    fi

    base=$(basename $file)
    local cwidth=${#base}
    [ $CMD_WIDTH -lt $cwidth ] && CMD_WIDTH=$cwidth
    local mwidth=$((cwidth + $(str_len "$blurb") + 2))

    [ $MENU_WIDTH -lt $mwidth ] && MENU_WIDTH=$mwidth
    MENU_LIST="${MENU_LIST}file $base $blurb\n"
}


start_menu_list() {
    MENU_WIDTH=0
    CMD_WIDTH=0
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
end_menu_list() {
    local cmd  blurb
    while read type cmd blurb; do
        printf "%s: %s\n" "$(lpad_word $((CMD_WIDTH + 1)) "$cmd")" "$blurb"
    done <<Show_cmds
$(echo -e "$MENU_LIST")
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

edit_file() {
    local pause sudo exec check opts
    clear
    if [ -z "${1##-*}" ]; then
        opts=$1 ; shift
        [ -z "${opts##-*s*}" ] && sudo=$SUDO
    fi

    local file=$1

    if ! sudo test -e $file; then
        db_msg "File not file:$white $file"
        return
    fi

    if ! sudo test -w $file; then
        db_msg "Cannot write to file:$white $file"
        return
    fi


    clear
    restore_tty

    local cmd="$EDITOR $file"
    printf "\e[0;0H$cyan$exec$cmd$nc\n"

    ($sudo bash -c "$cmd" 2>&1)&
    local pid=$!
    wait $pid

   clear
   hide_tty
   redraw
}

view_file() {
    local pause sudo exec check opts
    clear
    if [ -z "${1##-*}" ]; then
        opts=$1 ; shift
        [ -z "${opts##-*s*}" ] && sudo=$SUDO
    fi

    local file=$1

    clear
    restore_tty

    local cmd="less -R $file"
    printf "\e[0;0H$cyan$exec$cmd$nc\n"

    (bash -c "$cmd" 2>&1)&
    local pid=$!
    wait $pid

   clear
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
    echo -n "${cyan}Press <Enter> to continue$nc"
    read -s xxx
}


#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
new_menu() {
    local name=$1  title=$2  menu=$3
    grid_read_new $name "$menu"
    grid_narrow y=3 title="$title"
    grid_center_x
    grid_fill_y 15
    grid_finalize
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
select_menu() {
    local name=$1

    PARENT_MENU=$THIS_MENU
    THIS_MENU=$name

    grid_activate $name
    clear
    redraw
}

get_time() { cut -d" " -f22 /proc/self/stat ;}

delta_time() {
    get_seconds $(($(get_time) - $1))
}

get_seconds() {
    local dt=${1:-$(get_time)}
    printf "%03d" $dt | sed -r 's/(..)$/.\1/'
}


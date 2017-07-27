
TAB=$(printf "\t")

ME=$(basename $0)

DEBUG_KEYS=0

#FIXME:
log_file=$ME.log

trap on_exit EXIT

case $(tty) in
    */pts/*) SCREEN_IN_VT=     ; TTY_OFF=0 ;;
          *) SCREEN_IN_VT=true ; TTY_OFF=1 ;;
esac

SCREEN__COLORS="
BORDER_COLOR
TITLE1_COLOR
TITLE2_COLOR
TITLE3_COLOR
MSG_COLOR
QUOTE_COLOR"

log_fmt_1="  %-16s %s"

restart() { :; }

SCREEN_BOX_STYLE=-s

set_color() {
    local e=$(printf "\e")

         black="$e[30m";        red="$e[31m";      green="$e[32m";
         amber="$e[33m";       blue="$e[34m";    magenta="$e[35m";
          cyan="$e[36m";      grey2="$e[37m";

          grey="$e[1;30m";    rose="$e[1;31m";  lt_green="$e[1;32m";
        yellow="$e[1;33m";  violet="$e[1;34m";      pink="$e[1;35m";
       lt_cyan="$e[1;36m";   white="$e[1;37m";

            nc="$e[0m";

      black_bg="$e[40m";     red_bg="$e[41m";    green_bg="$e[42m";
      amber_bg="$e[43m";    blue_bg="$e[44m";  magenta_bg="$e[45m";
       cyan_bg="$e[46m";   white_bg="$e[47m"
           rev="$e[7m";  under_line="$e[4m";         bold="$e[1m"

    clear="$e[2;J"; cursor_off="$e[?25l"; cursor_on="$e[?25h"

    light_SCREEN_BORDER_COLOR=$white
    light_SCREEN_TITLE1_COLOR=$yellow
    light_SCREEN_TITLE2_COLOR=$cyan
    light_SCREEN_TITLE3_COLOR=$magenta
    light_SCREEN_MSG_COLOR=$yellow

    dark_SCREEN_BORDER_COLOR=$blue
    dark_SCREEN_TITLE1_COLOR=$magenta
    dark_SCREEN_TITLE2_COLOR=$green
    dark_SCREEN_TITLE3_COLOR=$magenta
    dark_SCREEN_MSG_COLOR=$blue

    medium_SCREEN_BORDER_COLOR=$green
    medium_SCREEN_TITLE1_COLOR=$green
    medium_SCREEN_TITLE2_COLOR=$cyan
    medium_SCREEN_TITLE3_COLOR=$magenta
    medium_SCREEN_MSG_COLOR=$amber
}

dbq() { echo "$white$*$SCREEN_MSG_COLOR" ;}

set_color

screen_set() {
    local nam val v1 v2
    while [ $# -gt 0 ]; do
        [ -z "${1##*=*}" ] || fatal "illegal screen_set argument: \"%s\".  Must be name=value" "$white$1"
        nam=${1%%=*}
        val=${1#*=}
        v1=${val%%,*}
        v2=${val#*,}
        case $nam in
            title1)        SCREEN_TITLE_1=$val ;;
            title2)        SCREEN_TITLE_2=$val ;;
            title3)        SCREEN_TITLE_3=$val ;;
            border)         SCREEN_BORDER=$val ;;
               box)      SCREEN_BOX_STYLE=$val ;;

                 *) fatal "Unknown screen_set parameter: %s" "$white$nam" ;;
        esac
        shift
    done
}

screen_draw() {
    screen_set "$@"
    [ "$CRULER" ] && cruler $CRULER $nc$amber$rev
    screen_draw_box
    screen_draw_titles
}

screen_draw_titles() {
    screen_set "$@"
    if [ "$SCREEN_DID_BOX" ]; then
        ctext 1 "" " $SCREEN_TITLE_1 " $SCREEN_TITLE1_COLOR
    else
        cline 1 "$SCREEN_TITLE_1"      $SCREEN_TITLE1_COLOR
    fi
    #return
    cline 2 "$SCREEN_TITLE_2"          $SCREEN_TITLE2_COLOR
    cline 3 "$SCREEN_TITLE_3"          $SCREEN_TITLE3_COLOR

}

screen_draw_box() {
    SCREEN_DID_BOX=
    #log1 box-style $SCREEN_BOX_STYLE
    #log1 box       "$SCREEN_BOX"
    [ -n "$SCREEN_BOX_STYLE" -a -n "$SCREEN_BOX" ] || return
    SCREEN_DID_BOX=true
    box $SCREEN_BOX_STYLE $SCREEN_BOX $SCREEN_BORDER_COLOR
}

on_enter() {
    db_msg "on_enter(\"$1\", \"$2\", \"$3\")"
}

screen_init() {

    SCREEN_X0=$((SCREEN_BORDER + 1))
    SCREEN_Y0=$((SCREEN_BORDER + 1))
    SCREEN_RAW_WIDTH=${WIDTH:-$(stty size | cut -d" " -f2)}
    SCREEN_RAW_HEIGHT=${HEIGHT:-$(stty size | cut -d" " -f1)}

    SCREEN_HEIGHT=$((SCREEN_RAW_HEIGHT - 2 * SCREEN_BORDER))
    SCREEN_WIDTH=$(( SCREEN_RAW_WIDTH  - 2 * SCREEN_BORDER))
    SCREEN_BOX=
    [ $SCREEN_BORDER -gt 0 ] && SCREEN_BOX="1 1 $SCREEN_RAW_WIDTH $SCREEN_RAW_HEIGHT"

    if [ -z "DID_INIT" ]; then
        log "\n\n$bold$yellow>>>>>$cyan $ME started $(date) $yellow<<<<<$nc"
        DID_INIT=true
    fi
    log1 "v-height" $SCREEN_HEIGHT
    log1 "v-width" $SCREEN_WIDTH
}

main_loop() {
    local key msg
    while true; do

        key=$(get_key)
        msg=
        [ $DEBUG_KEYS -eq 1 ] && msg="key=$key"   
        [ $DEBUG_KEYS -eq 2 ] && msg=$(printf "$key" | od -t x1 | head -n1 | sed 's/^0\+ //')
        db_msg "$msg"

        key_callback $key && continue

        case $key in
            up|down|left|right|home|end) grid_nav $key         ;;
               A) clear; redraw                                ;;
               a) redraw                                       ;;
            [kK]) DEBUG_KEYS=$(( (DEBUG_KEYS + 1) % 3))        ;;
     [qQ]|escape) log "Quiting $ME"; clear; exit               ;;
               s) db_msg "Screen size: %dx%d" $(stty size)     ;;
               S) do_bash_shell                                ;; 
            [dD]) grid_deactivate                              ;;
               C) toggle_center_labels                         ;;
               c) toggle_color                                 ;;
            [rR]) restart                                      ;;
            [xX]) grid_clear                                   ;;
           [hH?]) do_help                                      ;;
           enter) on_enter_                                    ;;
        esac
    done
}

key_callback() { return 1; }

toggle_color() {
    local scheme=$COLOR_SCHEME
    case $scheme in
        light) scheme=medium  ;;
       medium) scheme=dark    ;;
            *) scheme=light   ;;
    esac
    set_color_scheme $scheme
    grid_activate
    screen_draw
    db_msg "Set color scheme to $scheme"
}

set_color_scheme() {
    local scheme=$1 var val
    for var in $GRID__COLORS; do
        eval GRID_$var=\$${scheme}_GRID_$var
    done

    for var in $SCREEN__COLORS; do
        eval SCREEN_$var=\$${scheme}_SCREEN_$var
    done

    grid_set_markers
    COLOR_SCHEME=$scheme
}


toggle_center_labels() {
    grid_clear
    if [ -z "$CENTER_LABELS" ]; then
        grid_center_labels
        grid_activate
        db_msg "Centered Labels"
        CENTER_LABELS=1
    else
        grid_fill_labels
        grid_activate
        db_msg "Left Align Labels"
        CENTER_LABELS=
    fi
}

ruler() {
    local i y=$1 color=$2
    printf "\e[$y;1H$color"
    for i in $(seq 1 $SCREEN_RAW_WIDTH); do
        printf $((i % 10))
    done
    printf $nc
}

cruler() {
    local i y midx
    for y in $(echo "$1" | sed 's/,/ /g'); do
        y=$(($y + SCREEN_Y0)) color=$2
        midx=$((SCREEN_RAW_WIDTH/2))
        printf "\e[$y;1H$color"
        for i in $(seq 1 $midx); do
            printf $((i % 10))
        done

        for i in $(seq 1 $midx); do
            printf "\e[$y;$((SCREEN_RAW_WIDTH -i + 1))H"
            printf $((i % 10))
        done
        printf $nc
    done
}

lab_len() {
    local len=$(str_len "$1")
    if echo "$1" | grep -P -q "\e\[[0-9]+C"; then
        local jump=$(echo "$1" | sed -r "s/.*\x1B\[([0-9]+)C.*/\1/")
        echo $((len + jump - 4))
    else
        echo $len
    fi
}

# Note, the 2nd regex helps shells that don't know about unicode
# as long as sed is unicode-aware then you are okay.  Unfortunately
# BusyBox sed doesn't work here.
str_len() {
    local msg_nc=$(echo "$*" | sed -r -e 's/\x1B\[[0-9;]+[mK]//g' -e 's/./x/g')
    echo ${#msg_nc}
}

str_rtrunc() {
    local msg=$(echo "$1" | sed -r 's/\x1B\[[0-9;]+[mK]//g')
    local len=$2
    echo "$msg" | sed -r "s/(.{$len}).*/\1/"
}

str_ltrunc() {
    local msg=$(echo "$1" | sed -r 's/\x1B\[[0-9;]+[mK]//g')
    local len=$2
    echo "$msg" | sed -r "s/.*(.{$len})$/\1/"
}

ctext() {
    local y=$1 x0=${2:-$((SCREEN_RAW_WIDTH / 2))} msg=$3 color=$4
    local len=$(str_len "$msg")
    local x=$((1 + x0 - len/2))
    printf "$color\e[$y;${x}H$msg"
}

cline() {
    #log "cline(\"$1\", \"$2$nc\")"
    local y=$1 msg=$2 color=$3
    [ "$msg" ] || return
    msg=$(echo "$msg" | sed "s/<color>/$color/g")

    local x=$SCREEN_X0
    local len=$(str_len "$msg")
    local width=$SCREEN_WIDTH
    [ $len -ge $width ] && msg=$(str_rtrunc "$msg" $width)
    local pad1=$(( (width - len) / 2))
    local pad2=$((width - len - pad1))
    printf "\e[$y;${x}H$color%${pad1}s%s%${pad2}s" "" "$msg" ""
}

quote() {
    printf "$SCREEN_QUOTE_COLOR$*<color>"
}

db_msg() {
    local y=$(( SCREEN_Y0 + SCREEN_HEIGHT - TTY_OFFSET - 1))
    local msg=$(printf "$@")
    printf "\e[$y;${SCREEN_X0}H$nc$SCREEN_MSG_COLOR"
    printf "%-${SCREEN_WIDTH}s" "$msg"
}

box() {
    local flag
    while [ $# -gt 0 -a -z "${1##-*}" ]; do
        flag=$flag${1#-}
        shift
    done

    #return
    local x0=$1 y0=$2 width=$3 height=$4 color=$5
    #log "box($flag $x0 $y0 $width $height ${color}XX$nc)"

    [ "$color" ] && printf "$nc$color"

    local iwidth=$((width - 2))
    local x1=$((x0 + width - 1))

    #-- Set up line style and colors

    [ "$ASCII_ONLY" ] && flag=A$flag
    case $flag in
      Ac) local hbar=" " vbar=" " tl_corn=" " bl_corn=" " tr_corn=" " br_corn=" " ;;
      Ad) local hbar="=" vbar="|" tl_corn="#" bl_corn="#" tr_corn="#" br_corn="#" ;;
      A*) local hbar="-" vbar="|" tl_corn="+" bl_corn="+" tr_corn="+" br_corn="+" ;;
       c) local hbar=" " vbar=" " tl_corn=" " bl_corn=" " tr_corn=" " br_corn=" " ;;
       b) local hbar="━" vbar="┃" tl_corn="┏" tr_corn="┓" bl_corn="┗" br_corn="┛" ;;
       d) local hbar="═" vbar="║" tl_corn="╔" tr_corn="╗" bl_corn="╚" br_corn="╝" ;;
       *) local hbar="─" vbar="│" tl_corn="┌" tr_corn="┐" bl_corn="└" br_corn="┘" ;;
    esac

    local bar=$(printf "%${iwidth}s" | sed "s/ /$hbar/g")
    printf "\e[$y0;${x0}H$tl_corn$bar$tr_corn"
    local y
    for y in $(seq $((y0 + 1)) $((y0 + height - 2))); do
        printf "\e[$y;${x0}H$vbar"
        printf "\e[$y;${x1}H$vbar"
    done
    printf "\e[$((y0 + height - 1));${x0}H$bl_corn$bar$br_corn"

}

get_key() {
    local key k1 k2 k3 k4
    read -s -N1
    k1=$REPLY
    read -s -N2 -t 0.001 k2
    read -s -N1 -t 0.001 k3 2>/dev/null
    read -s -N1 -t 0.001 k4 2>/dev/null
    key=$k1$k2$k3$k4

    case $key in
        $'\eOP\x00')  key=f1           ;;
        $'\eOQ\x00')  key=f2           ;;
        $'\eOR\x00')  key=f3           ;;
        $'\eOS\x00')  key=f4           ;;

        $'\e[[A')     key=f1           ;;
        $'\e[[B')     key=f2           ;;
        $'\e[[C')     key=f3           ;;
        $'\e[[D')     key=f4           ;;
        $'\e[[E')     key=f5           ;;

        $'\e[11~')    key=f1           ;;
        $'\e[12~')    key=f2           ;;
        $'\e[13~')    key=f3           ;;
        $'\e[14~')    key=f4           ;;
        $'\e[15~')    key=f5           ;;
        $'\e[17~')    key=f6           ;;
        $'\e[18~')    key=f7           ;;
        $'\e[19~')    key=f8           ;;
        $'\e[20~')    key=f9           ;;
        $'\e[21~')    key=f10          ;;
        $'\e[23~')    key=f11          ;;
        $'\e[24~')    key=f12          ;;
        $'\e[2~')     key=insert       ;;
        $'\e[3~')     key=delete       ;;
        $'\e[5~')     key=page-up      ;;
        $'\e[6~')     key=page-down    ;;
        $'\e[7~')     key=home         ;;
        $'\e[8~')     key=end          ;;
        $'\e[1~')     key=home         ;;
        $'\e[4~')     key=end          ;;
        $'\e[A')      key=up           ;;
        $'\e[B')      key=down         ;;
        $'\e[C')      key=right        ;;
        $'\e[D')      key=left         ;;

        $'\x7f')      key=backspace    ;;
        $'\x08')      key=backspace    ;;
        $'\x09')      key=tab          ;;
        $'\x0a')      key=enter        ;;
        $'\e')        key=escape       ;;
        $'\x20')      key=space        ;;

    esac
    printf "$key"
}

log1n() { log "$log_fmt_1" "$1:" "$2"        ;}
log1()  { log "$log_fmt_1" "$1:" "\"$2$nc\"" ;}

log2() { log "$log_fmt_2" "$@" ;}
log3() { log "$log_fmt_3" "$@" ;}

log_err() { log "${red}Error:$cyan $@" ;}
log_warn() { log "$bold${yellow}Warning:$nc$cyan $@" ;}
log() {
    [ "$log_file" ] || return
    printf "$@" >&2
    echo    $nc >&2
}

do_bash_shell() {
    restore_tty
    printf "${cyan}Use 'exit' or Ctrl-d to return to %s$nc\n" $ME
    PS1="Bash> " bash 2>&1
    hide_tty
    redraw
}

do_help() {
    if [ -z "$HELP_PAGE" ]; then
        db_msg "No help page was set"
        return
    fi
    do_command man -P /usr/bin/less $HELP_PAGE
}

do_command() {
    restore_tty
    "$@"
    hide_tty
    redraw
}

restore_tty() {
    [ -n "$ORIG_STTY" ] && stty $ORIG_STTY
    printf "$nc$clear$cursor_on"
    printf "\e[1;1H"
}

hide_tty() {
    [ "$ORIG_STTY" ]    || ORIG_STTY=$(stty -g)
    [ "$SCREEN_IN_VT" ] || trap restart WINCH
    clear
    stty cbreak -echo
    printf $cursor_off
}

fatal() {
    printf "$ME:$red Error:$cyan $@"
    echo $nc
    exit -1
}

screen_reset() {
    clear
    screen_init
}

# FIXME: does $@ get passed to the library??
need_root() {
    [ $UID -eq 0 ] && return
    #echo "The $ME program needs to be run as root"
    exec sudo -p "$ME: Enter password for user %u: " "$0" "$@"
}

in_vt() {
    [ "$SCREEN_IN_VT" ]
    return $?
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
set_window_title() {
    local fmt=$1
    printf "\e]0;$ME: $fmt\a" "$@"
    SET_WINDOW_TITLE=true
}

erase_window_title() {
    printf "\e]0; \a"
}

on_exit() {
    [ -n "$SET_WINDOW_TITLE" ] && erase_window_title
    [ -n "$ORIG_STTY" ] || return
    restore_tty
    printf "$cyan%s exited$nc\n" $ME
}


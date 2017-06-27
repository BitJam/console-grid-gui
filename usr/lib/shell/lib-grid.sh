GRID__SAVE="
BOX
CLEAR
DA_LEFT
DA_RIGHT
DATA_LIST
DEFAULT
DEFAULT_SEL
LEFT
MAX
MID_X
NAME
RIGHT
SEL
SEL_LEFT
SEL_RIGHT
TITLE
VALUE_LIST
VX0
VY0
LDMARK
LMARK
LPAD
MARGIN
RDMARK
RMARK
RPAD
STITLE_1
STITLE_2
STITLE_3
Y0
"

GRID__CLEAR="
LEFT_LAB
SHAPE
LMARK
LPAD
MARGIN
MAX_HEIGHT
MAX_WIDTH
ON_GOTO
RMARK
RPAD
S_TITLE_1
S_TITLE_2
S_TITLE_3
XBORDER
XGAP
YBORDER
YGAP"

GRID__COLORS="
BORDER_COLOR
TITLE_COLOR
DA_COLOR
DA_SEL_COLOR
LABEL_COLOR
SEL_COLOR
MARK_COLOR
DMARK_COLOR
DLAB_COLOR"

light_GRID_BORDER_COLOR=$cyan
light_GRID_TITLE_COLOR=$yellow
light_GRID_DA_COLOR=$nc
light_GRID_DA_SEL_COLOR=$nc$rev
light_GRID_LABEL_COLOR=$white
light_GRID_SEL_COLOR=$white$cyan_bg
light_GRID_MARK_COLOR=$yellow
light_GRID_DMARK_COLOR=$pink
light_GRID_DLAB_COLOR=$cyan

dark_GRID_BORDER_COLOR=$green
dark_GRID_TITLE_COLOR=$magenta
dark_GRID_DA_COLOR=$grey
dark_GRID_DA_SEL_COLOR=$grey$rev
dark_GRID_LABEL_COLOR=$blue
dark_GRID_SEL_COLOR=$white$blue_bg
dark_GRID_MARK_COLOR=$magenta
dark_GRID_DMARK_COLOR=$red
dark_GRID_DLAB_COLOR=$green

medium_GRID_BORDER_COLOR=$violet
medium_GRID_TITLE_COLOR=$green
medium_GRID_DA_COLOR=$amber
medium_GRID_DA_SEL_COLOR=$black$amber_bg
medium_GRID_LABEL_COLOR=$green
medium_GRID_SEL_COLOR=$white$cyan_bg
medium_GRID_MARK_COLOR=$cyan
medium_GRID_DMARK_COLOR=$pink
medium_GRID_DLAB_COLOR=$cyan

grid_read_new() {
    [ "$1" ] || fatal "Must supply grid_read_new with a name"

    grid_delete

    GRID_NAME=$1; shift

    local sep
    if [ "$1" ] && [ -z "${1##-sep=*}" ]; then
        sep=${1#-sep=}
        shift
    fi

    log "\nCreate $GRID_NAME grid"

    # Grab the remaining args as labels for the grid cells
    # Get count of labels and the maximum width
    local label data width=0 cnt=0 lab_width
    while read label; do
        [ "$label" ] || continue
        if [ "$sep" ]; then
            data=${label#*$sep}
            label=${label%%$sep*}
            GRID_DATA_LIST="$GRID_DATA_LIST$cnt:$data\n"
        fi
        [ -z "$label" ] && continue
        eval ${GRID_NAME}_GRID_LAB_$cnt=\$label
        lab_width=$(lab_len "$label")
        [ $width -lt $lab_width ] && width=$lab_width
        GRID_VALUE_LIST="$GRID_VALUE_LIST$cnt:$label\n"
        cnt=$((cnt + 1))
    done<<While_Read
$(echo "$1")
While_Read

    GRID_MAX=$((cnt - 1))
    GRID_LAB_WIDTH=$width
    #log1 grid-max       $GRID_MAX
    #log1 grid-lab-width $GRID_LAB_WIDTH

    return

    for cnt in $(seq 0 $GRID_MAX); do
        eval label=\$${GRID_NAME}_GRID_LAB_$cnt
        while [ ${#label} -lt $width ]; do
            label=$label-
        done
        eval ${GRID_NAME}_GRID_LAB_$cnt=\$label
        cnt=$((cnt + 1))
    done
}

grid_new() {
    local i sep name=$1; shift;

    [ "$1" ] && [ -z "${1##-sep=*}" ] && sep=$1 && shift
    local list=$(for i in "$@"; do echo "$i"; done)
    grid_read_new $name $sep "$list"

}

grid_delete() {
    local name
    for name in $GRID__CLEAR $GRID__SAVE; do
        eval unset GRID_$name
    done
    GRID_LDMARK="*"
    GRID_RDMARK="*"
    GRID_LMARK=">"
    GRID_RMARK="<"
    GRID_XBORDER=0
    GRID_YBORDER=0
}

grid_set() {
    local nam val v1 v2
    while [ $# -gt 0 ]; do
        [ -z "${1##*=*}" ] || fatal "illegal grid_set argument: \"%s\".  Must be name=value" "$white$1"
        nam=${1%%=*}
        val=${1#*=}
        v1=${val%%,*}
        v2=${val#*,}
        case $nam in
            border)     GRID_XBORDER=$v1    ;    GRID_YBORDER=$v2  ;;
               gap)        GRID_XGAP=$v1    ;       GRID_YGAP=$v2  ;;
              size)   GRID_MAX_WIDTH=$v1    ; GRID_MAX_HEIGHT=$v2  ;;
                xy)         GRID_VX0=$v1    ;        GRID_VY0=$v2  ;;
              mark)       GRID_LMARK=$v1    ;      GRID_RMARK=$v2  ;;
               pad)        GRID_LPAD=$v1    ;       GRID_RPAD=$v2  ;;
             dmark)       GRID_LDMARK=$v1   ;     GRID_RDMARK=$v2  ;;
              lpad)        GRID_LPAD=$val                          ;;
              rpad)        GRID_RPAD=$val                          ;;
            margin)      GRID_MARGIN=$val                          ;;
           default)     GRID_DEFAULT=$val                          ;;
             shape)       GRID_SHAPE=$val                          ;;
             lmark)       GRID_LMARK=$val                          ;;
             rmark)       GRID_RMARK=$val                          ;;
            ldmark)      GRID_LDMARK=$val                          ;;
            rdmark)      GRID_RDMARK=$val                          ;;
            height)  GRID_MAX_HEIGHT=$val                          ;;
             title)       GRID_TITLE=$val                          ;;
           stitle1)    GRID_STITLE_1=$val                          ;;
           stitle2)    GRID_STITLE_2=$val                          ;;
           stitle3)    GRID_STITLE_3=$val                          ;;
             width)   GRID_MAX_WIDTH=$val                          ;;
              xgap)        GRID_XGAP=$val                          ;;
              ygap)        GRID_YGAP=$val                          ;;
           on_goto)     GRID_ON_GOTO=$val                          ;;
             label)    GRID_LEFT_LAB=$val                          ;;
                 x)         GRID_VX0=$val                          ;;
                 y)         GRID_VY0=$val                          ;;

                 *) fatal "Unknown grid_set parameter: %s" "$white$nam" ;;
        esac
        shift
    done
}

grid_defaults() {
    : ${GRID_VX0:=1}
    : ${GRID_VY0:=1}

    : ${GRID_MAX_WIDTH:=$((SCREEN_WIDTH   - GRID_VX0))}
    : ${GRID_MAX_HEIGHT:=$((SCREEN_HEIGHT - GRID_VY0))}
    [ $GRID_MAX_WIDTH  -lt 0 ] && GRID_MAX_WIDTH=$((SCREEN_WIDTH   + GRID_MAX_WIDTH))
    [ $GRID_MAX_HEIGHT -lt 0 ] && GRID_MAX_HEIGHT=$((SCREEN_HEIGHT + GRID_MAX_HEIGHT - GRID_VY0))

#--- Grid globals
    # : ${GRID_SEL_COLOR:=$white$cyan_bg}
    # : ${GRID_MARK_COLOR:=$yellow}
    # : ${GRID_LABEL_COLOR:=$white}
}

grid_truncate() {
    grid_defaults
    local cols=$(( (GRID_MAX_WIDTH  - 2 * GRID_XBORDER) / GRID_CELL_WIDTH ))
    local rows=$(( (GRID_MAX_HEIGHT - 2 * GRID_YBORDER) / (1 + GRID_YGAP) ))
    local max=$((rows * cols - 1))
    #log1 rows $rows
    #log1 cols $cols
    #log "Truncate GRID_MAX from %d to %d" $GRID_MAX $max
    #db_msg "Truncate GRID_MAX from %d to %d" $GRID_MAX $max
    [ $GRID_MAX -gt $max ] && GRID_MAX=$max
    grid_try_
}

grid_try() {
    grid_set "$@"
    grid_defaults
    grid_try_
}

grid_try_() {
    local l_len=$(str_len "$GRID_LMARK")
    local r_len=$(str_len "$GRID_RMARK")
    local m_len=$(str_len "$GRID_MARGIN")
    local lpad=$(printf "%${l_len}s" "")
    local rpad=$(printf "%${r_len}s" "")
    GRID_LPAD=$lpad
    GRID_RPAD=$rpad
    GRID_CELL_WIDTH=$((GRID_LAB_WIDTH + l_len + r_len + 2 * m_len))

    #log1 grid-pad "$GRID_MARGIN"
    #log1 grid-lpad "$GRID_LPAD"
    #log1 grid-rpad "$GRID_RPAD"

    local total=$((GRID_MAX + 1))
    local cell_width=$GRID_CELL_WIDTH
    local x_gap=${GRID_XGAP:-0}
    local y_gap=${GRID_YGAP:-0}
    local max_height=$GRID_MAX_HEIGHT
    local max_width=$GRID_MAX_WIDTH
    max_height=$((max_height - 2 * GRID_YBORDER))
    max_width=$((max_width   - 2 * GRID_XBORDER))

    #log1 max-width  $max_width
    #log1 max-height $max_height
    #log1 cell-width $cell_width

    case $GRID_SHAPE in
        narrow|wide|"") ;;
        *) error "Bad grid shape: \"$GRID_SHAPE\".  Wanted narrow or wide." ;;
    esac

    # Figure out row and column arrangement to fix in space provided

    local rows cols width height valid range
    for cols in $(seq 1 ${max_cols:-$total}); do

        # calculate #rows given # cols
        rows=$((total / cols))
        [ $((rows * cols)) -lt $total ] && rows=$((rows + 1))

        # Stop if more columns than rows FIXME
        [ "$GRID_SHAPE" != wide -a $cols -gt $rows ] && break

        width=$((cols * (cell_width + x_gap) - x_gap))

        height=$(( rows * (1 + y_gap) - y_gap))

        #log "cols=%2d  rows=%2d  width=%3d  height=%3d" $cols $rows $width $height

        [ $height -gt $max_height ] && continue
        [ $width  -gt $max_width  ] && break

        GRID_COLS=$cols
        GRID_ROWS=$rows
        valid=true
        [ "$GRID_SHAPE" = narrow ] && break
    done

    while [ $(( (GRID_COLS - 1) * GRID_ROWS)) -ge $total ]; do
        GRID_COLS=$((GRID_COLS - 1))
    done

    if [ -z "$valid" ]; then
        log_warn "No valid grid found"
        return 1
    fi

    GRID_XOFF=$((cell_width + x_gap))
    GRID_YOFF=$((1          + y_gap))

    local gwidth=$(( GRID_COLS * (cell_width + x_gap) - x_gap))
    local gheight=$((GRID_ROWS * (1          + y_gap) - y_gap))
    GRID_WIDTH=$((gwidth  + 2 * GRID_XBORDER))
    GRID_HEIGHT=$((gheight + 2 * GRID_YBORDER))

    #log1 grid-cols   $GRID_COLS
    #log1 grid-rows   $GRID_ROWS
    #log1 grid-width  $GRID_WIDTH
    #log1 grid-height $GRID_HEIGHT
}

grid_fill_y() {
    local top=$1  extra=$((GRID_MAX_HEIGHT - GRID_HEIGHT))
    #log1 extra $extra
    #log1 grid-vy0 $GRID_VY0
    GRID_VY0=$((GRID_VY0 + (top * extra) / 100))
    #log1 grid-vy0 $GRID_VY0
}

grid_center_x() {
    GRID_VX0=$((GRID_VX0 + (GRID_MAX_WIDTH - GRID_WIDTH + 1) /2))
}

grid_finalize() {
    local arg
    for arg; do
        case $arg in
            x=*|y=*) ;;
                  *) fatal "grid_finalize only takes x= and y= args"
        esac
    done
    grid_set "$@"

    GRID_X0=$((GRID_VX0 + SCREEN_X0 - 1))
    GRID_Y0=$((GRID_VY0 + SCREEN_Y0 - 1))

    local gx0=$((GRID_X0 + GRID_XBORDER))
    local gy0=$((GRID_Y0 + GRID_YBORDER))

    local xoff=$GRID_XOFF  yoff=$GRID_YOFF

    local max=$GRID_MAX
    local rows=$GRID_ROWS  max_row=$((GRID_ROWS -1))
    local cols=$GRID_COLS  max_col=$((GRID_COLS -1))

    #log1 bx0 $GRID_X0
    #log1 by0 $GRID_Y0
    #log1 gx0 $gx0
    #log1 gy0 $gy0
    #log1 xoff $xoff
    #log1 yoff $yoff

    local mid_row=$((max_row/2))
    local mid_col=$((max_col/2))

    # Calculate which cell the arrow keys will take you too and save the
    # destinations in a variable with the format up:down:left:right

    local up down left right row=-1 col=0 bot_right=0

    # First find index of bottom right cell
    for i in $(seq 0 $max); do

        # get row and column
        row=$((row + 1))
        if [ $row -gt $max_row ]; then
            row=0
            col=$((col + 1))
        fi
        [ $row -eq $max_row ] && bot_right=$i
    done

    GRID_DEFAULT_SEL=-1
    row=-1 col=0
    #printf "%2s: %s %s  %2s %2s %2s %2s\n" i C R up dn lt rt
    for i in $(seq 0 $max); do

        # get row and column
        row=$((row + 1))
        if [ $row -gt $max_row ]; then
            row=0
            col=$((col + 1))
        fi

        [ $row -eq $mid_row -a $col -eq $mid_col ] && : ${GRID_SEL:=$i}

        local gx=$((gx0 + col * xoff))
        local gy=$((gy0 + row * yoff))

        eval ${GRID_NAME}_GRID_XY_$i="'\e[$gy;${gx}H'"
        #eval ${GRID_NAME}_GRID_XY_$i="'\e[${y}B\e[${x}C'"

        #log "r=%2d c=%2d  @  x=%3d, y=%3d" "$col" "$row" "$x" "$y"

        up=$((i - 1))
        [ $up -lt 0 ] && up=$max

        down=$((i + 1))
        [ $down -gt $max ] && down=0

        if [ $i -eq 0 ]; then
            left=$bot_right
        else
            left=$((i - rows))
            [ $left -lt 0    ] && left=$((i + (cols - 1) * rows - 1))
            [ $left -gt $max ] && left=$((i + (cols - 2) * rows - 1))
            [ $left -lt 0    ] && left=$max
        fi

        if [ $i -eq $bot_right ]; then
            right=0
        else
            right=$((i + rows))
            [ $right -gt $max ] && right=$((i - (cols - 1) * rows + 1))
            [ $right -lt 0    ] && right=$((i - (cols - 2) * rows + 1))
            [ $right -gt $max ] && right=0
        fi

        eval ${GRID_NAME}_GRID_NAV_$i=\$up:\$down:\$left:\$right
        eval local lab=\$${GRID_NAME}_GRID_LAB_$i
        [ "$lab" = "$GRID_DEFAULT" ] && GRID_DEFAULT_SEL=$i
        #log "nav: %3d: (%3d,%3d) %2d %2d %2d %2d -- %s" $i $x $y $up $down $left $right "$lab"

    done

    GRID_MID_X=$((GRID_X0 + (GRID_WIDTH - 1 )/2))

     [ $GRID_XBORDER -gt 0 -a $GRID_XBORDER -gt 0 ] && \
         GRID_BOX="$GRID_X0 $GRID_Y0 $GRID_WIDTH $GRID_HEIGHT"

    [ "$COLOR_SCHEME" ] || set_color_scheme light
    grid_set_markers

    GRID_CLEAR="$(printf "%${GRID_CELL_WIDTH}s" "")"
    #log1 grid-clear "$GRID_CLEAR"
    #grid_grab_data
    grid_save
    #log1 grid-lab-color "$cyan${GRID_LABEL_COLOR}XXX$nc"

    [ $GRID_SEL -gt $GRID_MAX ] && GRID_SEL=$GRID_MAX
    [ $GRID_SEL -lt 0         ] && GRID_SEL=0

    return 0
}

grid_set_markers() {
    GRID_SEL_LEFT="$GRID_MARK_COLOR$GRID_LMARK$GRID_SEL_COLOR$GRID_MARGIN"
    GRID_SEL_RIGHT="$GRID_MARGIN$nc$GRID_MARK_COLOR$GRID_RMARK$nc"

    GRID_LEFT="$GRID_LPAD$GRID_MARGIN"
    GRID_RIGHT="$GRID_MARGIN$GRID_RPAD$nc"

    GRID_DA_LEFT="$GRID_LPAD$GRID_DA_SEL_COLOR$GRID_MARGIN"
    GRID_DA_RIGHT="$GRID_MARGIN$nc$GRID_RPAD"

    local gld="$(str_adjust_width_l "$GRID_LDMARK" "$GRID_LMARK")"
    GRID_LEFT_DEFAULT="$GRID_MARGIN$gld$GRID_LABEL_COLOR"
    local grd="$(str_adjust_width_r "$GRID_RDMARK" "$GRID_RMARK")"
    GRID_RIGHT_DEFAULT="$grd$nc$GRID_MARGIN"


    #log1 left-d-in "$GRID_LDMARK"
    #log1 right-d-in "$GRID_RDMARK"
    #log1 left-default  "$GRID_LEFT_DEFAULT"
    #log1 right-default "$GRID_RIGHT_DEFAULT"
}

str_adjust_width_l() {
    local str=$1 len=$(str_len "$2") slen=$(str_len "$1")
    if [ $slen -eq $len ]; then
        echo "$str"
    elif [ $slen -gt $len ]; then
        str_ltrunc "$str" $len
    else
        printf "%${len}s" "$str"
    fi
}

str_adjust_width_r() {
    local str=$1 len=$(str_len "$2") slen=$(str_len "$1")
    #log "len=$len  slen=$slen"
    if [ $slen -eq $len ]; then
        echo "$str"
    elif [ $slen -gt $len ]; then
        str_rtrunc "$str" $len
    else
        #log1 pfout "$(printf "%${len}s" "$str")"
        #printf "%-${len}s" "$str"
        #log "printf \"%-${len}s\" \"$str\""
        printf "%-${len}s" "$str"
    fi
}

grid_draw_box() {
    local flags=$1 color=$2
    [ "$GRID_BOX" ] || return
    box $flags $GRID_BOX $color
}

grid_title() {
    color=$1
    [ "$GRID_TITLE" ] && ctext $GRID_Y0 $GRID_MID_X " $GRID_TITLE " $color
}

grid_save() {
    local var val
    for var in $GRID__SAVE; do
        eval val=\$GRID_$var
        eval ${GRID_NAME}_GRID_$var=\$val
    done
}

grid_restore() {
    local var val name=$1
    for var in $GRID__SAVE; do
        eval val=\$${name}_GRID_$var
        eval GRID_$var=\$val
        [ -z "${var##*_LIST}" ] && continue
        #log1 GRID_$var "$val"
    done
    grid_set_markers
}

grid_show() {
    local var val
    for var in $GRID__SAVE; do
        eval val=\$GRID_$var
        [ -z "${var##*_LIST}" ] && continue
        #log1 GRID_$var "$val"
    done
}

grid_nav() {
    local field new key=$1
    case $key in
        up) field=1        ;;
      down) field=2        ;;
      left) field=3        ;;
     right) field=4        ;;
      home) new=0          ;;
       end) new=$GRID_MAX  ;;
         *) return 1       ;;
    esac

    if [ "$field" ]; then
        eval local nav=\$${GRID_NAME}_GRID_NAV_$GRID_SEL
        new=$(echo $nav | cut -d: -f$field)
    fi
    [ "$new" ] && grid_goto $new
}

grid_goto() {
    local new=$1 color=$nc$GRID_LABEL_COLOR
    [ "$new" = "$GRID_SEL" ] && return 1
    if [ "$new" -gt "$GRID_MAX" ]; then
        log_err "in grid_goto() new=$new max=$GRID_MAX"
        new=$GRID_MAX
    fi

    local lab xy
    eval lab=\$${GRID_NAME}_GRID_LAB_$GRID_SEL
    eval xy=\$${GRID_NAME}_GRID_XY_$GRID_SEL
    printf "$xy$nc"
    local left=$GRID_LEFT
    if [ $GRID_DEFAULT_SEL -eq $GRID_SEL ]; then
        local gld="$GRID_DMARK_COLOR$GRID_LEFT_DEFAULT$GRID_DLAB_COLOR"
        local grd="$GRID_DMARK_COLOR$GRID_RIGHT_DEFAULT"
        echo "$lab" | sed -r "s/^( *)(.*[^ ])( *)$/\1$gld\2$grd\3/"
    else
        printf "$color$GRID_LEFT$lab$GRID_RIGHT"
    fi

    GRID_SEL=$new

    eval lab=\$${GRID_NAME}_GRID_LAB_$GRID_SEL
    eval xy=\$${GRID_NAME}_GRID_XY_$GRID_SEL
    printf "$xy$GRID_SEL_LEFT$lab$GRID_SEL_RIGHT"

    [ "$GRID_ON_GOTO" ] && eval ${GRID_NAME}_on_goto \"\$lab\" \"\$GRID_SEL\"

    #grid_select
    #grid_grab_data

    return 0
}


grid_grab_data() {
    GRID_VALUE=$(echo -e "$GRID_VALUE_LIST" | grep ^$GRID_SEL: | sed -r 's/^[0-9]+://' \
        | sed -r -e 's/^ +//' -e 's/ +$//')

    #log1 grid-value "$GRID_VALUE"

    [ "$GRID_DATA_LIST" ] || return

    GRID_DATA=$(echo -e "$GRID_DATA_LIST" | grep ^$GRID_SEL: | sed -r 's/^[0-9]+://')
    #log1 grid-data "$GRID_DATA"
}

grid_select() {
    local lab xy
    eval lab=\$${GRID_NAME}_GRID_LAB_$GRID_SEL
    eval xy=\$${GRID_NAME}_GRID_XY_$GRID_SEL
    printf "$xy$GRID_SEL_LEFT$lab$GRID_SEL_RIGHT"
}

grid_redraw_() {
    [ $GRID_SEL         -gt $GRID_MAX ] && GRID_SEL=$GRID_MAX
    #[ $GRID_DEFAULT_SEL -gt $GRID_MAX ] && GRID_DEFAULT_SEL=-1

    local color=$nc$1  dmark_color=$2  sel_left=$3  sel_right=$4
    local dlab_color=${5:-$color}
    local i lab xy
    printf $color
    for i in $(seq 0 $GRID_MAX); do
        eval lab=\$${GRID_NAME}_GRID_LAB_$i
        eval xy=\$${GRID_NAME}_GRID_XY_$i
        printf "$xy"

        if [ $i = $GRID_SEL ]; then
            printf "$sel_left$lab$sel_right$nc$color"
        else
            if [ $GRID_DEFAULT_SEL -eq $i ]; then
        local gld="$dmark_color$GRID_LEFT_DEFAULT$dlab_color"
        local grd="$dmark_color$GRID_RIGHT_DEFAULT"
                echo "$lab" | sed -r "s/^( *)(.*[^ ])( *)$/\1$gld\2$grd\3/"
            else
                printf "$color$GRID_LEFT$lab$GRID_RIGHT"
            fi
        fi
    done
}

grid_activate() {
    local name=$1

    [ "$name" ] && grid_restore $name

    [ -n "$GRID_STITLE_1" -o -n "$GRID_STITLE_2" -o -n "$GRID_STITLE_3" ] && \
        screen_draw title1="$GRID_STITLE_1" title2="$GRID_STITLE_2" title3="$GRID_STITLE_3"

    grid_draw_box -b "$GRID_BORDER_COLOR"
    grid_title       "$GRID_TITLE_COLOR"
    grid_redraw_     "$GRID_LABEL_COLOR" "$GRID_DMARK_COLOR" "$GRID_SEL_LEFT" \
        "$GRID_SEL_RIGHT" "$GRID_DLAB_COLOR"
}

grid_deactivate() {
    printf $nc
    grid_draw_box -s "$GRID_DA_COLOR"
    grid_title       "$GRID_DA_COLOR"
    grid_redraw_     "$GRID_DA_COLOR" "$GRID_DA_COLOR" "$GRID_DA_LEFT" "$GRID_DA_RIGHT"
}



grid_list() {
    local name=$1; shift
    #log "max=$GRID_MAX"
    #log "cell_width=$GRID_CELL_WIDTH"
    for i in $(seq 0 $max); do
        eval local nav=\$${GRID_NAME}_GRID_NAV_$i
        eval local lab=\$${GRID_NAME}_GRID_LAB_$i
        eval local col=\$${GRID_NAME}_GRID_COL_$i
        eval local row=\$${GRID_NAME}_GRID_ROW_$i
        #log "%2d: x:%02d y:%02d  nav:%-12s  lab:%s" "$i" "$col" "$row" "$nav" "$lab"
    done
}

grid_center_labels() {
    local width=${1:-$GRID_LAB_WIDTH}

    local i label diff pad_l pad_r

    for i in $(seq 0 $GRID_MAX); do
        eval label=\$${GRID_NAME}_GRID_LAB_$i
        label=$(echo "$label" | sed -r -e 's/^\s+//' -e 's/\s+$//')
        diff=$((width - ${#label}))
        [ $diff -le 0 ] && continue
        pad_l=$((diff / 2))
        pad_r=$((diff - pad_l))
        #printf "%2d %2d %2d\n" $width $pad_l $pad_r
        label=$(printf "%${pad_l}s%s%${pad_r}s" "" "$label" "")
        eval ${GRID_NAME}_GRID_LAB_$i=\"\$label\"
    done
}

grid_fill_labels() {
    local width=${1:-$GRID_LAB_WIDTH}

    local i label diff pad_l pad_r

    for i in $(seq 0 $GRID_MAX); do
        eval label=\$${GRID_NAME}_GRID_LAB_$i
        label=$(echo "$label" | sed -r -e 's/^\s+//' -e 's/\s+$//')
        diff=$((width - ${#label}))
        [ $diff -le 0 ] && continue
        #printf "%2d %2d %2d\n" $width $pad_l $pad_r
        label=$(printf "%s%${diff}s" "$label" "")
        eval ${GRID_NAME}_GRID_LAB_$i=\"\$label\"
    done
}


grid_left_labels() {

    local i label diff pad_l pad_r

    for i in $(seq 0 $GRID_MAX); do
        eval label=\$${GRID_NAME}_GRID_LAB_$i
        label=$(echo "$label" | sed -r -e 's/^\s+//' -e 's/\s+$//')
        eval ${GRID_NAME}_GRID_LAB_$i=\"\$label\"
    done
}


grid_clear() {
    grid_draw_box -c
    printf $nc
    local i xy
    for i in $(seq 0 $GRID_MAX); do
        eval xy=\$${GRID_NAME}_GRID_XY_$i
        printf "$xy$GRID_CLEAR"
    done
}

grid_narrow() {
    grid_set "$@"
    grid_set shape=narrow dmark="***,***"
    grid_set border=1,1 gap=1,1 mark="▶▶,◀◀"
    while true; do
        grid_try               && break
        grid_try ygap=0        && break
        grid_try mark="▶,◀"    && break

        log_err "Truncating grid $GRID_NAME ..."

        grid_truncate
    done
}

grid_large() {
    grid_set "$@"
    grid_set shape=wide dmark="***,***"
    grid_set margin="  " border=2,2 gap=2,1 mark="▶▶,◀◀"
    while true; do
        grid_try                                  && break
        grid_try ygap=0                           && break
        grid_try gap=2,1 margin=" "               && break
        grid_try mark="▶,◀" border=2,1 gap=0,0    && break
        grid_try border=1,1 gap=0,0 margin=""     && break

        log_err "Truncating list of window managers ..."

        grid_truncate
    done
    grid_center_x
}

on_enter_() {
    grid_grab_data
    local val=$(printf "%s" "$GRID_VALUE" |sed -r 's/\x1B\[[0-9;]+[mKC]//g')

    if type ${GRID_NAME}_cmd &>/dev/null ; then
        local cmd=$(echo "$val" | cut -d: -f1)

        return_to_main "$cmd" && return
        eval ${GRID_NAME}_cmd \"\$cmd\"

    elif type ${GRID_NAME}_on_enter &>/dev/null; then
        eval ${GRID_NAME}_on_enter \"\$val\" \"\$GRID_DATA\" \"\$GRID_SEL\"

    else
        db_msg "Would do action %s" "$white$val" ;
    fi
}


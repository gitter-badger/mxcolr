#!/usr/bin/env bash

################################
GEN_MIN_DISTANCE=30
ATTMP_WARN_THRESHOLD=7
################################
diff_real () { echo "df=($1 - $2); if (df < 0) { df=df* -1}; print df" | bc -l; }
diff_under () {
  local diff; diff=$(diff_real "$1" "$2")
  echo "$diff < $GEN_MIN_DISTANCE" | bc -l
}

################################
sort_lightness () {
  local H=0;local highest
  local L=100;local lowest

  while [ "$1" ]; do
    local l; l=$(pastel format lch-lightness "${!1}")
    (( $(echo "$l < $L" | bc) )) && L="$l" && lowest="$1"
    (( $(echo "$l > $H" | bc) )) && H="$l" && highest="$1"
    shift
  done

  echo "$highest:$lowest"
}
expandp () {
  echo "1 $1"
  while [ "$1" ]; do
    pastel format hex "${!1}"
    shift
  done
}
################################
lightest () {
  local l; l=$(sort_lightness "$@" | cut -d':' -f1)
  pastel paint "$(pastel textcolor "${!l}")" -o "${!l}" "${l}"
}
################################
darkest () {
  local d; d=$(sort_lightness "$@" | cut -d':' -f2)
  pastel paint "$(pastel textcolor "${!d}")" -o "${!d}" "${d}"
}
################################

# shellcheck disable=SC2034
gen_random () {
  local attmp="${1:-1}"

  # PressToContinue "XOPT $XOPT"
  local strategy="${XOPT:-lch}" ; [[ "$strategy" == 'lch' ]]   && strategy='lch_hue'
  local xcal='0.16'             ; [[ "$strategy" == 'vivid' ]] && xcal='0.08'

  WBG="$(pastel random -n 1 -s "$strategy" | pastel saturate     "$xcal" | pastel darken "$xcal" | pastel format hex)"
  SBG="$(pastel random -n 1 -s "$strategy" | pastel mix - "$WBG" -f 0.80 | pastel darken "$xcal" | pastel format hex)"
  EBG="$(pastel random -n 1 -s "$strategy" | pastel mix - "$WBG" -f 0.80 | pastel darken "$xcal" | pastel format hex)"

  local WBG_SAT; WBG_SAT="$(pastel format hsl-saturation "$WBG")"
  local SBG_SAT; SBG_SAT="$(pastel format hsl-saturation "$SBG")"
  local EBG_SAT; EBG_SAT="$(pastel format hsl-saturation "$EBG")"

  mlg "S1:: S $SBG_SAT - W $WBG_SAT - E $EBG_SAT"
  (( $(echo "$SBG_SAT < 0.60" | bc) )) && SBG="$(pastel saturate 0.20 "$SBG" | pastel format hex)"
  (( $(echo "$EBG_SAT < 0.60" | bc) )) && EBG="$(pastel saturate 0.20 "$EBG" | pastel format hex)"
  mlg "S2:: S $SBG_SAT - W $WBG_SAT - E $EBG_SAT"

  mlg "$(pastel format hsl-saturation "$SBG") $(pastel format hsl-saturation "$EBG")"

  local WBG_HUE; WBG_HUE="$(pastel format hsl-hue "$WBG")"
  local SBG_HUE; SBG_HUE="$(pastel format hsl-hue "$SBG")"
  local EBG_HUE; EBG_HUE="$(pastel format hsl-hue "$EBG")"

  local S_fail;S_fail="$(diff_under "$WBG_HUE" "$SBG_HUE")"
  local E_fail;E_fail="$(diff_under "$WBG_HUE" "$EBG_HUE")"
  local X_fail;X_fail="$(diff_under "$SBG_HUE" "$EBG_HUE")"
  mlg "HU:: S $SBG_HUE - W $WBG_HUE - E $EBG_HUE"
  mlg "HX:: S $S_fail - E $E_fail - X $X_fail"

  if (( S_fail || E_fail || X_fail )); then
    ! (( attmp % ATTMP_WARN_THRESHOLD )) && PressToContinue "failed $attmp attempts, still continue?"
    gen_random $((++attmp))
  else
    fillCols ' ▪'; InfoDone "${strategy^^} generated, after $attmp attempts,proceeding"; return
  fi
}
# well almost! not anymore..
gen_idempotents () {
  local ds;ds=$(darkest SBG WBG EBG)

  C01="$(pastel mix ${!ds} "$(pastel random -n 1 -s lch_hue)" -f 0.5 | pastel mix - crimson       -f 0.6 | pastel mix - deeppink          -f 0.7 | pastel saturate 0.08 | pastel format hex)"
  C02="$(pastel mix ${!ds} "$(pastel random -n 1 -s lch_hue)" -f 0.5 | pastel mix - darkseagreen  -f 0.6 | pastel mix - mediumspringgreen -f 0.7 | pastel saturate 0.08 | pastel format hex)"
  C03="$(pastel mix ${!ds} "$(pastel random -n 1 -s lch_hue)" -f 0.5 | pastel mix - orange        -f 0.6 | pastel mix - coral             -f 0.7 | pastel saturate 0.08 | pastel format hex)"
  C04="$(pastel mix ${!ds} "$(pastel random -n 1 -s lch_hue)" -f 0.5 | pastel mix - blue          -f 0.6 | pastel mix - deepskyblue       -f 0.7 | pastel saturate 0.08 | pastel format hex)"
  C05="$(pastel mix ${!ds} "$(pastel random -n 1 -s lch_hue)" -f 0.5 | pastel mix - indigo        -f 0.6 | pastel mix - slateblue         -f 0.7 | pastel saturate 0.08 | pastel format hex)"
  C06="$(pastel mix ${!ds} "$(pastel random -n 1 -s lch_hue)" -f 0.5 | pastel mix - darkturquoise -f 0.6 | pastel mix - deepskyblue       -f 0.7 | pastel saturate 0.08 | pastel format hex)"

  for i in {09..14}; do
    local c="C0$(echo "$i - 8" | bc)"; c="${!c}"
    declare -g "C$i=$(pastel lighten   0.10 "$c" | pastel format hex)"
  done

  WBX="$(pastel saturate  0.30 "$WBG" | pastel lighten 0.10 | pastel format hex)"
  WFX="$(pastel textcolor      "$WBX" | pastel darken  0.20 | pastel format hex)"

  for i in {1..6}; do
    local c="C0$i"; c="${!c}"
    declare -g "CX$i=$(pastel saturate    0.30 "$c" | pastel darken   0.04 | pastel format hex)"
    declare -g "CY$i=$(pastel desaturate  0.32 "$c" | pastel lighten  0.10 | pastel format hex)"
  done

  WFG="$(pastel textcolor "$WBG" | pastel darken 0.2 | pastel format hex)"
  EFG="$(pastel textcolor "$EBG" | pastel darken 0.2 | pastel saturate 0.20 | pastel format hex)"
  SFG="$(pastel textcolor "$SBG" | pastel darken 0.2 | pastel saturate 0.20 | pastel format hex)"

  InfoDone
} 

# shellcheck disable=SC2034
gen_shades () {
  local darkestSeed;darkestSeed=$(darkest SBG WBG EBG)
  pastel paint -b -o "${!darkestSeed}" "$(pastel textcolor "${!darkestSeed}")" " darkest seed : ${darkestSeed} "
  XBG="$(pastel set hsl-saturation   0.18 "${!darkestSeed}" | pastel set hsl-lightness 0.06 | pastel format hex)"
  OBG="$(pastel lighten 0.08 "$XBG" | pastel saturate 0.04 | pastel format hex)"; # OBG="$(pastel desaturate  0.20 "$WBG" | pastel darken  0.30 | pastel format hex)"

  if (( "$DEBUG" )); then
    __print_hexes $(echo DK{0..9})
    __print_hexes $(echo DL{0..9})
    __print_hexes $(echo LK{0..9})
    Demo_shades4; echo
    printf '%10s %10s %10s %10s %10s %10s\n' "expoSin" "expoCos" "expoArc"
  fi

  # local base=$(pastel darken "0.1" "$XBG" | pastel desaturate "0.2")
      # pastel lighten "$3" "$base" | \

  __gen_shade () {
    pastel desaturate "0.2" "$XBG" | \
      pastel lighten "$3" | \
      pastel "$1" "$2" | \
      pastel format hex
    }

  for i in {0..9}; do
    local act1=lighten
    local act2=saturate

    local expoArc="0$(echo "scale=2; e(a($i-3))/10" | bc -l)"
    local expoSin="0$(echo "scale=2; e(s($i))/10" | bc -l)"
    local expoCos="0$(echo "scale=2; e(c($i))/10" | bc -l)"

    declare -g "DL$i=$(__gen_shade $act2 $expoSin $expoArc)"
    declare -g "DK$i=$(__gen_shade $act2 $expoCos $expoArc)"
    declare -g "LK$i=$(pastel lighten 0.2 \
      $(__gen_shade $act2 $expoArc $expoArc) | pastel desaturate 0.07 | pastel format hex)"

    (( "$DEBUG" )) && printf '%10s %10s %10s  %10s %10s %10s\n' "$expoSin" "$expoCos" "$expoArc"
  done

  if (( "$DEBUG" )); then
    Demo_shades4
    __print_hexes $(echo DK{0..9})
    __print_hexes $(echo DL{0..9})
    __print_hexes $(echo LK{0..9})
  fi

  OFG="$WBX"
  C00="$DL3"
  C08="$DK4"
  C07="$DL7"
  XFG="$DK8"
  C15="$LK9"

  InfoDone
}

# #################
################################
GeneratePalette () { 
  gen_random
  gen_idempotents
  gen_shades
  gen_ansi

  SaveSeed
  SaveTheme
  InfoDone
}
################################
################################
UpdatePalette () {
  . "$M_SEED" 2> /dev/null || . "$O_SEED"
  gen_idempotents
  gen_shades
  gen_ansi
  set_hexless

  SaveTheme
  InfoDone
}

# s (x)  The sine of x, x is in radians.
# c (x)  The cosine of x, x is in radians.
# a (x)  The arctangent of x, arctangent returns radians.
# l (x)  The natural logarithm of x.
# e (x)  The exponential function of raising e to the value x.
# j (n,x) The Bessel function of integer order n of x.

(( "$DEBUG" )) && gen_shades
(( "$DEBUG" )) && gen_idempotents
(( "$DEBUG" )) && Demo && Demo_slant && Demo_hexes


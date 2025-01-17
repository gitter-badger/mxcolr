#!/usr/bin/env bash

ListSnapshots () {
  local snapshots=("$MXSNAP"/*)

  total="${#snapshots[@]}"
  local slen;slen="$(MXDots)";slen="${#slen}"
  for sid in "${!snapshots[@]}"; do
    local snap=${snapshots[$sid]}; mlg "$snap"

    [ -e "$snap"/mx-seed ]  && mv "$snap"/mx-seed  "$snap"/seed.mx; # legacy name
    [ -e "$snap"/theme.mx ] && mv "$snap"/theme.mx "$snap"/root.mx; # legacy name

    . "$snap"/root.mx
    local slabel; slabel="$(basename "$snap" | cut -d'_' -f2-3)"
    local brk; brk=$(tput cols);brk=$((brk/(slen * 2)))
    if ! (( $1 )); then 
      ! (( sid % brk )) && echo
      printf ' '
      MXSep
      (diff "$O_SEED" "$snap"/seed.mx &>/dev/null  && ( Demo_mxname "$sid" )) \
        || pastel paint -o "$XBG" -b -n "$XFG" "$(printf '%#2d\n' "$sid")"
              MXDots
              MXSep
    fi
  done

  echo;echo; pastel paint "$XFG" -n "select "; pastel paint "$XFG" -b -n "(0-$((total-1))): "

  if (( $1 )); then
    choice="$((( RANDOM % $total )))"
  else
    read -r choice
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then 
    pastel paint "$C01" -b "($choice) numbers only "
    ListSnapshots
    return
  fi

  local selected="${snapshots["$((choice))"]}"

  if [ -n "$selected" ]; then
    mlg "selected $selected"
    mlg "choice $choice"
    pastel paint "$XFG" -b "selected ${selected} [$choice]"
    . "$selected"/root.mx
    MXDots; MXSep
    Demo
    [[ -n "$TMUX" ]] && . "$MXBASE"/plugins/2-tmux.sh && apply_tmux
    PromptConfirm; if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then ListSnapshots $*; fi
    cp "$selected"/seed.mx "$M_SEED"
    ReGenerate
    return
  else
    pastel paint "$C01" -b "($choice) out of range "
    sleep 3
    ListSnapshots
    return
  fi
}
## #####################
SaveSnapshot () {
  . "$OTHEME"
  Demo_card
  fillCols
  Demo
  Info "[${MXNAME}]  Saving Snapshot"

  local snapshots=("$MXSNAP"/*)

  mlg ">total pre"
  local total; total=$(find "$MXSNAP"/* -type d 2>/dev/null | wc -l)
  mlg ">total $total"

  local highest; highest=$(find "$MXSNAP"/* -type d 2>/dev/null | cut -d'_' -f2 | sort --numeric-sort -r | head -n 1)

  mlg ">highest $highest"

  local ccount; ccount=$((highest+1))
  for sid in "${!snapshots[@]}"; do
    local snap=${snapshots[$sid]}; mlg "$snap"

    [ -e "$snap"/mx-seed ]  && mv "$snap"/mx-seed  "$snap"/seed.mx; # legacy name
    [ -e "$snap"/theme.mx ] && mv "$snap"/theme.mx "$snap"/root.mx; # legacy name

    if (diff "$O_SEED" "$snap"/seed.mx &>/dev/null); then
      mlg "snap exists $snap"
      . "$snap"/root.mx
      InfoError " duplicate 🢃🢃🢃"; InfoWarn "$snap"
      echo $snap
      PromptConfirm " Create anyway "; if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then return; fi
    fi
  done
  local stamp; stamp=$(date +%s); stamp="${stamp:((-8))}"
  local sname; sname="${stamp}_${ccount}_${MXNAME}"
  local spath=$MXSNAP/$sname
  Demo_mxname $ccount; echo
  PressToContinue "creating new snapshot"
  cp "$MXDIST" "$spath" -r
  InfoDone "$spath"
}


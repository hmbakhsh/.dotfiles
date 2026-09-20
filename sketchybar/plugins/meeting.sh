#!/bin/bash

ICALBUDDY=/opt/homebrew/bin/icalBuddy
SKETCHYBAR=/opt/homebrew/bin/sketchybar

now=$(/bin/date +%s)
today=$(/bin/date +%Y-%m-%d)
tomorrow=$(/bin/date -v+1d +%Y-%m-%d)
time_label=""
event_label="No upcoming meetings"
icon_color=0xff9ca3af
events_file=$(/usr/bin/mktemp -t sketchybar-calendar)
trap '/bin/rm -f "$events_file"' EXIT

"$ICALBUDDY" -ea -nc -npn -nrd \
  -ic 'haroon@36labs.ai,h@hbak.co' \
  -iep 'datetime,title' -po 'datetime,title' \
  -ps '| — |' -b '' -df '%Y-%m-%d' -tf '%H:%M' \
  eventsToday+1 > "$events_file" 2>/dev/null &
calendar_pid=$!

calendar_ready=false
for _ in {1..20}; do
  if ! /bin/kill -0 "$calendar_pid" 2>/dev/null; then
    wait "$calendar_pid"
    calendar_ready=true
    break
  fi
  /bin/sleep 0.1
done

if [[ "$calendar_ready" == false ]]; then
  /bin/kill "$calendar_pid" 2>/dev/null
  wait "$calendar_pid" 2>/dev/null
  $SKETCHYBAR --set "$NAME" label="" \
    --set meeting_event \
    label="Allow Calendar access" \
    icon.color=0xffffc857 \
    click_script="/usr/bin/open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars'"
  exit 0
fi

while IFS= read -r event; do
  [[ -n "$event" ]] || continue

  datetime="${event%% — *}"
  title="${event#* — }"
  title="${title# }"

  starts_at="${datetime%% - *}"
  ends_at="${datetime#* - }"
  [[ "$ends_at" != "$datetime" ]] || continue

  # icalBuddy omits the date from the end time for same-day events.
  if [[ "$ends_at" != *" at "* ]]; then
    ends_at="${starts_at%% at *} at $ends_at"
  fi

  # Calendar feeds often model OOO blocks as timed events rather than all-day
  # events. They are availability, not the next meeting.
  case "$title" in
    *[Oo][Uu][Tt]' '[Oo][Ff]' '[Oo][Ff][Ff][Ii][Cc][Ee]*|*[Oo][Oo][Oo]*) continue ;;
  esac

  start_epoch=$(/bin/date -j -f '%Y-%m-%d at %H:%M' "$starts_at" +%s 2>/dev/null) || continue
  end_epoch=$(/bin/date -j -f '%Y-%m-%d at %H:%M' "$ends_at" +%s 2>/dev/null) || continue
  (( end_epoch > now )) || continue

  event_date="${starts_at%% at *}"
  event_time="${starts_at##* at }"
  short_title="${title:0:22}"

  if (( start_epoch <= now )); then
    minutes_left=$(( (end_epoch - now + 59) / 60 ))
    time_label="${minutes_left} min left"
    event_label="$short_title"
    icon_color=0xffffffff
    break
  fi

  minutes=$(( (start_epoch - now) / 60 ))

  hour_24="${event_time%%:*}"
  minute="${event_time##*:}"
  if (( 10#$hour_24 >= 12 )); then
    period=pm
  else
    period=am
  fi
  hour_12=$(( 10#$hour_24 % 12 ))
  (( hour_12 == 0 )) && hour_12=12
  if [[ "$minute" == "00" ]]; then
    display_time="${hour_12}${period}"
  else
    display_time="${hour_12}:${minute}${period}"
  fi

  if (( minutes <= 10 )); then
    if (( minutes == 0 )); then
      time_label="Now"
      event_label="$short_title"
    else
      time_label="${minutes} min"
      event_label="until $short_title"
    fi
  elif [[ "$event_date" == "$today" ]]; then
    time_label="$display_time"
    event_label="$short_title"
  elif [[ "$event_date" == "$tomorrow" ]]; then
    time_label="Tmrw $display_time"
    event_label="$short_title"
  else
    continue
  fi

  icon_color=0xffffffff
  break
done < "$events_file"

$SKETCHYBAR --set "$NAME" \
  label="$time_label" \
  icon.color="$icon_color" \
  click_script="/usr/bin/open -a Calendar" \
  --set meeting_event \
  label="$event_label" \
  click_script="/usr/bin/open -a Calendar"

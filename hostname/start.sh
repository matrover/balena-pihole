#!/bin/bash

set -euo pipefail

echo "--- Hostname ---"

if [[ -z "${BALENA_SUPERVISOR_ADDRESS:-}" || -z "${BALENA_SUPERVISOR_API_KEY:-}" ]]; then
  echo "Could not set hostname: BALENA_SUPERVISOR_ADDRESS and BALENA_SUPERVISOR_API_KEY were not provided."
  echo "Add 'io.balena.features.supervisor-api' label to allow interacting with the supervisor."
  echo "See https://docs.balena.io/reference/supervisor/supervisor-api/#http-api-reference for details."
  exit 0
fi

get_device_name() {
  local device_name

  device_name="$(
    curl -fsSL "$BALENA_SUPERVISOR_ADDRESS/v2/device/name?apikey=$BALENA_SUPERVISOR_API_KEY" 2>/dev/null |
      jq -r '.deviceName // empty' 2>/dev/null || true
  )"

  if [[ -n "$device_name" ]]; then
    printf '%s' "$device_name"
    return 0
  fi

  printf '%s' "${BALENA_DEVICE_NAME_AT_INIT:-}"
}

sanitize_hostname() {
  local raw="$1"
  local cleaned

  cleaned="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
  cleaned="${cleaned:0:63}"
  cleaned="${cleaned%-}"

  printf '%s' "$cleaned"
}

CURRENT_HOSTNAME="$(
  curl -fsSL "$BALENA_SUPERVISOR_ADDRESS/v1/device/host-config?apikey=$BALENA_SUPERVISOR_API_KEY" |
    jq -r '.network.hostname'
)"
echo "Current hostname: $CURRENT_HOSTNAME"

REQUESTED_HOSTNAME="${SET_HOSTNAME:-device-name}"
TARGET_HOSTNAME="$REQUESTED_HOSTNAME"

if [[ "$REQUESTED_HOSTNAME" == "uuid" || "$REQUESTED_HOSTNAME" == "UUID" ]]; then
  TARGET_HOSTNAME="${BALENA_DEVICE_UUID:0:7}"
fi

if [[ "$REQUESTED_HOSTNAME" == "device-name" ]]; then
  TARGET_HOSTNAME="$(get_device_name)"
fi

if [[ -z "$TARGET_HOSTNAME" ]]; then
  echo "Skipping hostname set: no target hostname could be determined."
  exit 0
fi

SANITIZED_HOSTNAME="$(sanitize_hostname "$TARGET_HOSTNAME")"
if [[ -z "$SANITIZED_HOSTNAME" ]]; then
  echo "Skipping hostname set: '$TARGET_HOSTNAME' could not be converted to a valid hostname."
  exit 0
fi

if [[ "$SANITIZED_HOSTNAME" != "$TARGET_HOSTNAME" ]]; then
  echo "Sanitized hostname '$TARGET_HOSTNAME' -> '$SANITIZED_HOSTNAME'"
fi

echo "Target hostname: $SANITIZED_HOSTNAME"

if [[ "$CURRENT_HOSTNAME" == "$SANITIZED_HOSTNAME" ]]; then
  echo "Skipping hostname set: target matches current hostname."
  exit 0
fi

echo "Setting target hostname..."
curl -fsSL -X PATCH \
  --header "Content-Type:application/json" \
  --data '{"network": {"hostname": "'"$SANITIZED_HOSTNAME"'"}}' \
  "$BALENA_SUPERVISOR_ADDRESS/v1/device/host-config?apikey=$BALENA_SUPERVISOR_API_KEY"
echo -e "\nHostname updated!"

exit 0

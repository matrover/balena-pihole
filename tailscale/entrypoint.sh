#!/bin/sh
set -e

# Start tailscaled with variable substitution
/usr/local/bin/tailscaled \
  --socket=/tmp/tailscaled.sock \
  --statedir=/var/lib/tailscale \
  --tun=userspace-networking &

TAILSCALED_PID=$!
sleep 3

# Build tailscale up command
CMD="/usr/local/bin/tailscale --socket=/tmp/tailscaled.sock up"

# Add auth key
if [ -n "$TS_AUTHKEY" ]; then
  CMD="$CMD --authkey=$TS_AUTHKEY"
fi

# Add hostname
if [ -n "$TS_HOSTNAME" ]; then
  CMD="$CMD --hostname=$TS_HOSTNAME"
fi

# Add advertise routes
if [ -n "$TS_ADVERTISE_ROUTES" ]; then
  CMD="$CMD --advertise-routes=$TS_ADVERTISE_ROUTES"
fi

# Add accept routes
if [ "$TS_ACCEPT_ROUTES" = "true" ]; then
  CMD="$CMD --accept-routes"
fi

# Run tailscale up
eval "$CMD" || true

wait $TAILSCALED_PID

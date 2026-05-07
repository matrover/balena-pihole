FROM tailscale/tailscale:latest

# Copy entrypoint script that handles variable substitution
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

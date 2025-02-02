#!/bin/bash

# This script cleans up Docker resources that are not being used. Including images, containers, volumes. 

### !!! WARNING !!! ###
# This command is destructive and should be used with caution, as it permanently deletes all unused containers, images, networks, and volumes without recovery options. 
# This will also delete persistent data volumes!
# Always make sure, that you have a backup of your data before running this script.

# Script: cleanup_docker.sh
# Log file location
LOG_FILE="$(dirname "$0")/docker_cleanup.log"

# Run cleanup command and capture output
OUTPUT=$(docker system prune -af --volumes 2>&1)

# Extract reclaimed space amounts (excluding "Total reclaimed space: 0B" lines)
RECLAIMED_SPACES=$(echo "$OUTPUT" | grep -Po '(?<=Total reclaimed space: )[0-9.]+[A-Z]+' | grep -v '^0B$')

# Calculate total reclaimed space
TOTAL_RECLAIMED=0
for SPACE in $RECLAIMED_SPACES; do
  UNIT=${SPACE: -2} # Extract the unit (e.g., MB, GB)
  VALUE=${SPACE%${UNIT}} # Extract the numeric value
  VALUE=${VALUE//,/} # Remove any commas if present

  case $UNIT in
    KB) VALUE=$(echo "$VALUE / 1024 / 1024" | bc -l);; # Convert KB to GB
    MB) VALUE=$(echo "$VALUE / 1024" | bc -l);;       # Convert MB to GB
    GB) VALUE=$VALUE;;                                # Already in GB
    *) VALUE=0;;                                      # Unknown unit
  esac

  TOTAL_RECLAIMED=$(echo "$TOTAL_RECLAIMED + $VALUE" | bc -l)
done

# Get the current timestamp
TIMESTAMP=$(date '+%d.%m.%Y %H:%M:%S')

# Write the log entry only if there's something reclaimed
if (( $(echo "$TOTAL_RECLAIMED > 0" | bc -l) )); then
  printf "%s - Cleanup finished. Total reclaimed space: %.3f GB\n" "$TIMESTAMP" "$TOTAL_RECLAIMED" >> "$LOG_FILE"
else
  printf "%s - Cleanup finished. No space was reclaimed.\n" "$TIMESTAMP" >> "$LOG_FILE"
fi
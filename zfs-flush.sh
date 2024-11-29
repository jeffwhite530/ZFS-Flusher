#!/bin/bash
# zfs_flush.sh: Force ZFS sync, flush caches, and block devices with extensive logging.

set -euo pipefail

log_file="/var/log/zfs_flush.log"
zfs_pool="${1:-}"  # Pool name passed as an argument.

if [[ -z "$zfs_pool" ]]; then
  echo "Usage: $0 <zfs_pool_name>"
  exit 1
fi

log() {
  echo "$(date --iso-8601=seconds) - $1" | tee -a "$log_file"
}

resolve_real_devices() {
  local pool=$1
  local devices=()

  # Extract vdev names and resolve to block devices
  for vdev in $(zpool status "$pool" | awk '/ONLINE/ && !/raidz|pool|state/ {print $1}'); do
    if [[ -e "/dev/disk/by-partlabel/$vdev" ]]; then
      # Use by-partlabel if applicable
      devices+=("$(readlink -f "/dev/disk/by-partlabel/$vdev")")
    elif [[ -b "/dev/$vdev" ]]; then
      # Use normal block device path if applicable
      devices+=("/dev/$vdev")
    fi
  done

  echo "${devices[@]}"
}

log "Starting ZFS flush script for pool: $zfs_pool"

# Perform system-wide sync
log "Running sync to flush system buffers..."
sync
log "System buffers flushed."

# Drop caches
log "Dropping caches (echo 3 > /proc/sys/vm/drop_caches)..."
if echo 3 > /proc/sys/vm/drop_caches; then
  log "Caches successfully dropped."
else
  log "Failed to drop caches. Check permissions."
  exit 1
fi

# Synchronize the specified ZFS pool
log "Synchronizing ZFS pool: $zfs_pool..."
if zpool sync "$zfs_pool"; then
  log "Successfully synchronized pool: $zfs_pool"
else
  log "Failed to synchronize pool: $zfs_pool"
  exit 1
fi

# Retrieve real devices for the ZFS pool
real_devices=$(resolve_real_devices "$zfs_pool")
if [[ -z "$real_devices" ]]; then
  log "No real devices found for pool: $zfs_pool."
  exit 1
fi

# Log resolved devices
log "Resolved devices: $real_devices"

# Flush all real devices associated with the pool
for dev in $real_devices; do
  log "Flushing buffer for device: $dev"
  if blockdev --flushbufs "$dev"; then
    log "Successfully flushed device: $dev"
  else
    log "Failed to flush device: $dev"
    exit 1
  fi
done

log "ZFS flush script completed successfully for pool: $zfs_pool."


# ZFS Flush Automation

This project automates the periodic synchronization, cache clearing, and device buffer flushing for ZFS pools. Includes `systemd` files.

## Installation

1. Edit the service file and set the zpool name as the first arg of the script. Alternatively, create `/etc/systemd/system/zfs-flush.service.d/override.conf` with:

    ```ini
    [Service]
    ExecStart=
    ExecStart=/usr/local/bin/zfs-flush.sh your_zpool_name
    ```

1. Copy the files.

    ```shell
    sudo cp zfs-flush.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/zfs-flush.sh
    sudo cp zfs-flush.service /etc/systemd/system/
    sudo cp zfs-flush.timer /etc/systemd/system/
    ```

1. Enable the service.

    ```shell
    sudo systemctl daemon-reload
    sudo systemctl enable zfs-flush.timer
    sudo systemctl start zfs-flush.timer
    ```

## Test

```shell
sudo bash /usr/local/bin/zfs-flush.sh your-zpool-name
sudo systemctl start zfs-flush.service
sudo journalctl -u zfs-flush.service
sudo cat /var/log/zfs-flush.log
```

## Verify

```shell
sudo systemctl list-timers | grep zfs-flush
sudo journalctl -u zfs-flush.service
sudo cat /var/log/zfs-flush.log
```

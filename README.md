# Patch for Raspberry Pi OS Lite
* Fix was to append `-n 127.0.0.1` to `ExecStart=/usr/bin/pigpiod -l` in `/lib/systemd/system/pigpiod.service`

User Guide: https://wiki.geekworm.com/X-C1_Software

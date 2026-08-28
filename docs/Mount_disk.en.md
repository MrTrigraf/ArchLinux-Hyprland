# 💽 Mounting an Additional Disk

A guide for attaching a separate SSD (e.g. for games) with automatic mounting
via `/etc/fstab`. Partition identification is **strictly by UUID** (the system
has multiple disks, so LABELs may collide).

> ⚠️ **Warning:** formatting permanently erases all data on the disk. Make sure
> you picked the correct disk before running `wipefs` and `mkfs`.

> 📝 **About the `<disk>` and `<partition>` placeholders:** in the commands below
> these are **placeholders**, not real names. Substitute your own values from the
> `lsblk` output. A disk is the whole device (e.g. `/dev/sdb`, `/dev/nvme1n1`),
> a partition is a specific slice on it (e.g. `/dev/sdb1`, `/dev/nvme1n1p1`).
> On NVMe disks the partition is suffixed with `p`: disk `/dev/nvme1n1` →
> partition `/dev/nvme1n1p1`.

---

## ext4 or btrfs?

**ext4** — a time-tested journaling filesystem, the de-facto standard in the
Linux world. It's undemanding, delivers stable and predictable performance on
random operations, and needs virtually no maintenance. It doesn't support
snapshots or transparent compression — that's the price of its simplicity.

**btrfs** — a modern copy-on-write filesystem that brings snapshots, subvolumes
and transparent compression out of the box. The flexibility comes at the cost of
slightly higher overhead and a bit more attention to tuning details.

**What to pick:** for a games-only disk **ext4** is recommended — it's simpler,
faster on random access and needs no tuning; game assets are already compressed,
so btrfs compression gives little gain and snapshots are rarely needed for games.
Choose **btrfs** if you want state snapshots or transparent data compression.

---

## Steps

### 1. Identify the disk

```bash
lsblk -f
```

Find the target disk by size and note its name (`<disk>`) and the name of the
partition you'll create in the next steps (`<partition>`).

### 2. Wipe the disk

```bash
sudo wipefs --all /dev/<disk>
```

### 3. Create a partition

```bash
sudo cfdisk /dev/<disk>
```

In the menu: choose **GPT** → `New` (full size) → `Write` (confirm by typing
`yes`) → `Quit`.

### 4. Format the partition

Pick **one** option depending on the filesystem. The `-L Game` flag sets the
label during formatting:

```bash
# ext4
sudo mkfs.ext4 -L Game /dev/<partition>

# btrfs
sudo mkfs.btrfs -f -L Game /dev/<partition>
```

> 💡 **Alternative:** if you need to set or change the label separately (e.g. `-L`
> didn't work, or you want to rename it later), use:
> ```bash
> # ext4
> sudo e2label /dev/<partition> Game
> # btrfs (partition must be mounted; <mountpoint> is the mount path)
> sudo btrfs filesystem label <mountpoint> Game
> ```

### 5. Create the mount point

```bash
sudo mkdir -p /disks/game
```

> Standard mount paths:
>
> - `/media/`
> - `/mnt/`
> - `/run/media/<user>/`

### 6. Get the partition UUID

```bash
sudo blkid /dev/<partition>
```

Copy the `UUID="..."` value (without quotes).

### 7. Add to `/etc/fstab`

```bash
sudo vim /etc/fstab
```

Append **one** line for your filesystem (insert your UUID from the previous step):

```
# ext4
UUID=<your-uuid>  /disks/game  ext4   defaults,noatime  0 2

# btrfs
UUID=<your-uuid>  /disks/game  btrfs  rw,noatime,compress=zstd:1,ssd,discard=async,space_cache=v2,nodev,nosuid  0 0
```

Field notes: `noatime` — don't update file access times (less SSD wear, faster);
for btrfs `compress=zstd:1` is light compression, `ssd`/`discard=async` are SSD
optimizations; the last field (fsck) is `2` for ext4 (check after the root
partition) and `0` for btrfs (btrfs doesn't use traditional boot-time fsck).

> 💡 **Showing the disk in the file manager.** If you want the disk to appear in
> the GNOME Files (Nautilus) sidebar next to your other drives, add `x-gvfs-show`
> to the mount options. It works with any filesystem (both ext4 and btrfs). Just
> append `,x-gvfs-show` to your line's option list, for example:
>
> ```
> # ext4
> UUID=<your-uuid>  /disks/game  ext4   defaults,noatime,x-gvfs-show  0 2
>
> # btrfs
> UUID=<your-uuid>  /disks/game  btrfs  rw,noatime,compress=zstd:1,ssd,discard=async,space_cache=v2,nodev,nosuid,x-gvfs-show  0 0
> ```
>
> Without this option the disk won't show up in the sidebar on paths like `/mnt`
> or `/disks` — it's not about the path itself, it's specifically `x-gvfs-show`.
> After editing, restart Nautilus (`nautilus -q`); if it doesn't appear right
> away, log out and back in.

### 8. Verify BEFORE rebooting

```bash
sudo systemctl daemon-reload
sudo mount -a
mount | grep game
```

If `mount -a` ran without errors and the last command shows the partition, the
`fstab` is correct. **If an error appears — fix `fstab` now**, before rebooting:
a broken `fstab` can drop the boot into an emergency shell.

### 9. Reboot

```bash
reboot
```

### 10. Transfer disk ownership to your user

By default the new partition is owned by `root`, and writing to it requires
`sudo`. To work with the disk without elevated privileges, change the owner.

First, find your username and primary group (if you forgot them):

```bash
whoami      # username
id -gn      # primary group
groups      # all groups you belong to
```

Then change the owner (substitute your `user:group`):

```bash
sudo chown -R <user>:<group> /disks/game
```

---

## Post-reboot check

```bash
mount | grep game     # partition is mounted
lsblk -f              # shows the Game label and mount point
```

Done — the disk mounts automatically on every boot.

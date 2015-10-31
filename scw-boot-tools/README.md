# initrd/*scw-boot-tools*

## Build

```bash
make
```

---

## scw-update-server-state

Allow to inform the API about the current server state or to interact with userdatas

### Usage

```command
$ scw-update-server-state [ OPTIONS ] params
   -s STATE
   -u "[KEY[=[VALUE]]]"
```

### Use cases

- https://github.com/scaleway/initrd/blob/2cdbb76fbec5b4d7590a81366bf904569cae32e1/Openbsd/tree-Openbsd-armv7/.profile#L26-L48
- https://github.com/scaleway/initrd/blob/74e348ff0e1c3bc28b0403615439cbb572e240e0/Linux/tree-armv7l/functions#L42

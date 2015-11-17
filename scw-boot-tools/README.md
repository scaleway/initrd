# initrd/*scw-boot-tools*

## Build

```bash
make
```

---

## scw-update-server-state

Allow to inform the API about the current server state or to interact with user datas

### Usage

```command
$ scw-update-server-state [ OPTIONS ] params
   -s STATE
   -u "[KEY[=[VALUE]]]"
```

### Use cases

- https://github.com/scaleway/initrd/blob/ad66c637a89ceec7dcce9a4ba2d170f1f43094bc/Openbsd/tree-Openbsd-armv7/.profile#L26-L48
- https://github.com/scaleway/initrd/blob/ad66c637a89ceec7dcce9a4ba2d170f1f43094bc/Linux/tree-common/init#L251

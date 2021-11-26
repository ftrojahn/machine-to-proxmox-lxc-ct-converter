# convert any gnu/linux machine into a proxmox lxc container #

#### root ssh access on target machine required ##### 
#### run skript @proxmox host with root privileges ##### 

```
./convert.sh \
-n test \
-t target.domain.tld \
-v /var/tmp/tarpath \
-i 114 \
-s 10 \
-a 192.168.111.63 \
-b vmbr0 \
-g 192.168.111.64 \
-m 2048 \
-d default \
-p foo
# -r 1 
```

```
convert.sh -h|--help
 -n|--name [lxc container name]
 -c|--tarcreate [use target machine, if not set: standard debian 10]
 -v|--tmpvolume [instead of /tmp ]
 -r|--removetar [remove tar after successful creation ]
 -t|--target [target machine ssh uri]
 -i|--id [proxmox container id]
 -s|--root-size [rootfs size in GB]
 -a|--ip [target container ip]
 -b|--bridge [bridge interface]
 -g|--gateway [gateway ip]
 -m|--memory [memory in mb]
 -d|--disk-storage [target proxmox storage pool]
 -p|--password [root password for container (min. 5 chars)]
```

#!/bin/bash
usage()
{
    cat <<EOF
$1 -h|--help
 -n|--name [lxc container name]
 -c|--tarcreate [use target machine, if not set: standard debian 10]
 -t|--target [target machine ssh uri]
 -i|--id [proxmox container id]
 -s|--root-size [rootfs size in GB]
 -a|--ip [target container ip]
 -b|--bridge [bridge interface]
 -g|--gateway [gateway ip]
 -m|--memory [memory in mb]
 -d|--disk-storage [target proxmox storage pool]
 -p|--password [root password for container (min. 5 chars)]
EOF
    return 0
}

options=$(getopt -o n:c:t:i:s:a:b:g:m:d:p:f -l help,name:,tarcreate:,target:,id:,root-size:,ip:,bridge:,gateway:,memory:,disk-storage:,password:,foo: -- "$@")
if [ $? -ne 0 ]; then
        usage $(basename $0)
    exit 1
fi
eval set -- "$options"

while true
do
    case "$1" in
        -h|--help)      usage $0 && exit 0;;
        -n|--name)      name=$2; shift 2;;
        -c|--tarcreate) tarcreate=$2; shift 2;;
        -t|--target)    target=$2; shift 2;;
        -i|--id)        id=$2; shift 2;;
        -s|--root-size) rootsize=$2; shift 2;;
        -a|--ip)        ip=$2; shift 2;;
        -b|--bridge)    bridge=$2; shift 2;;
        -g|--gateway)   gateway=$2; shift 2;;
        -m|--memory)    memory=$2; shift 2;;
        -p|--password)  password=$2; shift 2;;
        -d|--disk-storage) storage=$2; shift 2;;
        --)             shift 2; break ;;
        *)              break ;;
    esac
done

collectFS() {
    tar -czvvf - -C / \
	--exclude="sys" \
	--exclude="dev" \
	--exclude="run" \
	--exclude="proc" \
	--exclude="swap.img" \
	.
}
#	--exclude="*.log" \
#	--exclude="*.log*" \
#	--exclude="*.gz" \
#	--exclude="*.sql" \

if [ $tarcreate ] ; then
# get from remote
ssh "root@$target" "$(typeset -f collectFS); collectFS" \
    > "/tmp/${name}_amd64.tar.gz"
template="/tmp/${name}_amd64.tar.gz"
elif [ -f "/tmp/${name}_amd64.tar.gz" ] ; then
# use existing
template="/tmp/${name}_amd64.tar.gz"
elif [ -f "/var/lib/vz/template/cache/${name}_amd64.tar.gz" ] ; then
# use existing
template="/var/lib/vz/template/cache/${name}_amd64.tar.gz"
else
# use default
template="/var/lib/vz/template/cache/debian-10-standard_10.7-1_amd64.tar.gz"
fi

pct create $id "/tmp/$name.tar.gz" \
  --description LXC \
  --hostname $name \
  --features nesting=1 \
  --memory $memory \
  --net0 name=eth0,ip=dhcp,bridge=$bridge \
  --rootfs Storage:$rootsize --password $password

rm -rf "/tmp/$name.tar.gz"

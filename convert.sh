#!/bin/bash
usage()
{
    cat <<EOF
$1 -h|--help
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
EOF
    return 0
}

options=$(getopt -o n:c:v:r:t:i:s:a:b:g:m:d:p:f -l help,name:,tarcreate:,tmpvolume:,removetar:,target:,id:,root-size:,ip:,bridge:,gateway:,memory:,disk-storage:,password:,foo: -- "$@")
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
        -v|--tmpvolume) tmpvolume=$2; shift 2;;
        -r|--removetar) removetar=$2; shift 2;;
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
	--exclude="./sys" \
	--exclude="./dev" \
	--exclude="./run" \
	--exclude="./proc" \
	--exclude="./tmp" \
	--exclude="./var/tmp" \
	--exclude="./lib/modules" \
	--exclude="swapfile" \
	--exclude="./var/spool/postfix/dev/random" \
	--exclude="./var/spool/postfix/dev/urandom" \
	--exclude="swap.img" \
	.
}
#	--exclude="*.log" \
#	--exclude="*.log*" \
#	--exclude="*.gz" \
#	--exclude="*.sql" \

if [ -n "$tmpvolume" ] && [ -d "$tmpvolume" ] ; then
	echo using "$tmpvolume" 
else
	tmpvolume='/tmp'
fi

if [ $tarcreate ] ; then
# get from remote
ssh "root@$target" "$(typeset -f collectFS); collectFS" \
    > "${tmpvolume}/${name}_amd64.tar.gz"
template="${tmpvolume}/${name}_amd64.tar.gz"
elif [ -f "${tmpvolume}/${name}_amd64.tar.gz" ] ; then
# use existing
template="${tmpvolume}/${name}_amd64.tar.gz"
elif [ -f "/var/lib/vz/template/cache/${name}_amd64.tar.gz" ] ; then
# use existing
template="/var/lib/vz/template/cache/${name}_amd64.tar.gz"
else
# use default
template="/var/lib/vz/template/cache/debian-10-standard_10.7-1_amd64.tar.gz"
fi

pct create $id "${template}" \
  --description LXC \
  --hostname $name \
  --features nesting=1 \
  --memory $memory \
  --net0 name=eth0,ip=$ip/24,gw=$gateway,bridge=$bridge,firewall=1 \
  --ostype debian \
  --unprivileged 1 \
  --storage $storage \
  --rootfs "$storage":$rootsize,mountoptions=noatime \
  --password $password \
|| exit 5


if [ $removetar ] && [ -f $template ] ; then
	rm -f "${tmpvolume}/$name_amd64.tar.gz"
fi

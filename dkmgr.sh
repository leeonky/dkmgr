image_tag_of() {
	local tag=$(cat "/var/lib/dcs/$(basename $1)/$2/tag")
	if [ "$tag" == "" ]; then
		tag="latest"
	fi
	echo $tag
}

record_tag() {
	sudo mkdir -p "/var/lib/dcs/$(basename $1)/$2/"
	echo $3 | sudo tee "/var/lib/dcs/$(basename $1)/$2/tag"
}

docker_run() {
	local TCP_EXPORT_PORTS=(22 3000 5000)
	local UDP_EXPORT_PORTS=()

	local tcp_mapping
	local udp_mapping

	local p
	for p in ${TCP_EXPORT_PORTS[@]}
	do
		tcp_mapping="-p $(($p+40000)):$p/tcp $tcp_mapping"
	done
	for p in ${UDP_EXPORT_PORTS[@]}
	do
		udp_mapping="-p $(($p+40000)):$p/udp $udp_mapping"
	done

	sudo docker run --name $2 -d --privileged=true -v ~/:/home/devuser/share/:rw -v ~/.ssh:/home/devuser/.ssh $tcp_mapping $udp_mapping $1
}

is_container_running() {
	sudo docker ps --filter "name=$1" | grep "\s$1\$" -q
}

is_container_created() {
	sudo docker ps --filter "name=$1" -a | grep "\s$1\$" -q
}

start_container() {
	local inc_name=$2
	local image_name=$1
	if ! is_container_running $inc_name; then
		if ! is_container_created $inc_name; then
			local tag=$(image_tag_of $image_name $inc_name)
			docker_run $image_name:$tag $inc_name
		else
			sudo docker start $inc_name
		fi
	fi
}

stop_container() {
	sudo docker stop $1
}

login_container() {
	if ! is_container_running $2; then
		start_container $1 $2
	fi
	local ip=$(sudo docker inspect $2 | grep '"IPAddress"' | awk -F\" '{print $4}')
	ip="127.0.0.1"
	ssh devuser@$ip -p 40022
}

update_image() {
	local new_tag=$3
	local inc_name=$2
	local image_name=$1
	local last_tag=$(image_tag_of $image_name $inc_name)
	if [ "$last_tag" == "$new_tag" ]; then
		return
	fi
	sudo docker pull "$image_name:$new_tag"
	record_tag $image_name $inc_name $new_tag
	if [ "$last_tag" != "" ] && [ "$last_tag" != "$new_tag" ]; then
		sudo docker stop $inc_name
		sudo docker rm $inc_name
		sudo docker rmi "$image_name:$last_tag"
	fi
}

delete_container() {
	sudo docker stop $1
	sudo docker rm $1
}

docker_management() {
	local new_tag=$4
	local inc_name=$3
	local image_name=$2
	case $1 in
	start)
		start_container $image_name $inc_name
	;;
	stop)
		stop_container $inc_name
	;;
	restart)
		stop_container $inc_name
		start_container $image_name $inc_name
	;;
	login)
		login_container $image_name $inc_name
	;;
	update)
		update_image $image_name $inc_name $new_tag
	;;
	delete)
		delete_container $inc_name
	esac
}


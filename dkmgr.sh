image_tag_of() {
	local tag=$(cat "/var/lib/dcs/"$(basename $1)"/tag")
	if [ "$tag" == "" ]; then
		tag="latest"
	fi
	echo $tag
}

docker_run() {
	sudo docker run --name $2 -d --privileged=true -v ~/share:/home/devuser/share/:rw -v ~/.ssh:/home/devuser/.ssh $1
}

is_container_running() {
	[ "$(sudo docker ps --filter "name=$1" -q)" != "" ]
}

is_container_created() {
	[ "$(sudo docker ps --filter "name=$1" -qa)" != "" ]
}

start_container() {
	local inc_name=$2
	local image_name=$1
	if ! is_container_running $inc_name; then
		if ! is_container_created $inc_name; then
			local tag=$(image_tag_of $image_name)
			docker_run $image_name:$tag $inc_name
		else
			instance_run $inc_name
		fi
	fi
}

stop_container() {
	sudo docker stop $1
}

docker_management() {
	local inc_name=$3
	local image_name=$2
	case $1 in
	start)
		start_container $image_name $inc_name
	;;
	stop)
		stop_container $inc_name
	;;
	esac
}


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

start_container() {
	local inc_name=$2
	local image_name=$1
	local tag=$(image_tag_of $image_name)
	docker_run $image_name:$tag $inc_name
}

docker_management() {
	local inc_name=$3
	local image_name=$2
	start_container $image_name $inc_name
}

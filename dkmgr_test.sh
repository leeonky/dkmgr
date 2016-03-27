. dkmgr.sh
. $SHUNIT2_MOCK

test_container_first_start() {
	mock_function start_container
	docker_management start 'img' 'inc'
	mock_verify start_container HAS_CALLED_WITH 'img' 'inc'
}

test_start_container() {
	mock_function image_tag_of 'echo 1'
	mock_function docker_run

	start_container 'img' 'inc'

	mock_verify image_tag_of HAS_CALLED_WITH 'img'
	mock_verify docker_run HAS_CALLED_WITH 'img:1' 'inc'	
}

test_image_tag_of() {
	mock_function cat 'echo 1.0'

	local tag=$(image_tag_of 'test/img')

	mock_verify cat HAS_CALLED_WITH '/var/lib/dcs/img/tag'
	assertEquals '1.0' "$tag"
}

test_image_tag_of_with_latest_default() {
	mock_function cat ''

	local tag=$(image_tag_of 'test/img')

	mock_verify cat HAS_CALLED_WITH '/var/lib/dcs/img/tag'
	assertEquals 'latest' "$tag"
}

test_docker_run() {
	mock_function sudo

	docker_run 'img:0' 'inc'

	mock_verify sudo HAS_CALLED_WITH docker run --name inc -d --privileged=true -v ~/share:/home/devuser/share/:rw -v ~/.ssh:/home/devuser/.ssh 'img:0'

}


. $SHUNIT2_BIN

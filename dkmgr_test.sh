. dkmgr.sh
. $SHUNIT2_MOCK

test_container_first_start() {
	mock_function start_container
	docker_management start 'img' 'inc'
	mock_verify start_container HAS_CALLED_WITH 'img' 'inc'
}

test_start_container_with_dock_run_when_no_contain() {
	mock_function is_container_running 'return 1'
	mock_function is_container_created 'return 1'
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

test_start_container_again() {
	mock_function is_container_running
	mock_function docker_run

	start_container 'img' 'inc'

	mock_verify is_container_running HAS_CALLED_WITH 'inc'
	mock_verify docker_run NEVER_CALLED
}

test_is_container_running_when_stopped() {
	mock_function sudo

	is_container_running 'inc'
	
	assertFalse $?
	mock_verify sudo HAS_CALLED_WITH docker ps --filter 'name=inc' -q
}

test_is_container_running_when_running() {
	mock_function sudo 'echo aaa'

	is_container_running 'inc'
	
	assertTrue $?
	mock_verify sudo HAS_CALLED_WITH docker ps --filter 'name=inc' -q
}

test_restart_container() {
	mock_function is_container_running 'return 1'
	mock_function is_container_created
	mock_function image_tag_of
	mock_function docker_run
	mock_function instance_run

	start_container 'img' 'inc'

	mock_verify is_container_created HAS_CALLED_WITH 'inc'
	mock_verify instance_run HAS_CALLED_WITH 'inc'
	mock_verify image_tag_of NEVER_CALLED
	mock_verify docker_run NEVER_CALLED
}

test_is_container_created_when_created() {
	mock_function sudo 'echo id'

	is_container_created 'inc'

	assertTrue $?
	mock_verify sudo HAS_CALLED_WITH docker ps --filter 'name=inc' -qa
}

test_is_container_created_when_not_created() {
	mock_function sudo

	is_container_created 'inc'

	assertFalse $?
	mock_verify sudo HAS_CALLED_WITH docker ps --filter 'name=inc' -qa
}

test_stop_runner() {
	mock_function stop_container

	docker_management stop img inc

	mock_verify stop_container HAS_CALLED_WITH 'inc'
}

test_stop_container() {
	mock_function sudo

	stop_container inc

	mock_verify sudo HAS_CALLED_WITH docker stop 'inc'
}

. $SHUNIT2_BIN

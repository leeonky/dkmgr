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

	mock_verify image_tag_of HAS_CALLED_WITH 'img' 'inc'
	mock_verify docker_run HAS_CALLED_WITH 'img:1' 'inc'	
}

test_image_tag_of() {
	mock_function cat 'echo 1.0'

	local tag=$(image_tag_of 'test/img' 'inc')

	mock_verify cat HAS_CALLED_WITH '/var/lib/dcs/img/inc/tag'
	assertEquals '1.0' "$tag"
}

test_image_tag_of_with_latest_default() {
	mock_function cat ''

	local tag=$(image_tag_of 'test/img' 'inc')

	mock_verify cat HAS_CALLED_WITH '/var/lib/dcs/img/inc/tag'
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

test_start_closed_container() {
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

test_instance_run() {
	mock_function sudo

	instance_run inc

	mock_verify sudo HAS_CALLED_WITH docker start 'inc'
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

test_restart_container() {
	mock_function stop_container
	mock_function start_container

	docker_management restart img inc

	mock_verify stop_container HAS_CALLED_WITH 'inc'
	mock_verify start_container HAS_CALLED_WITH 'img' 'inc'
}

test_login_running_container() {
	mock_function is_container_running
	mock_function sudo 'echo "\"IPAddress\": \"1.2.3.4\",
	        \"SecondaryIPAddresses\": null,"'
	mock_function ssh
	mock_function start_container

	docker_management login img inc

	mock_verify is_container_running HAS_CALLED_WITH 'inc'
	mock_verify sudo HAS_CALLED_WITH docker inspect 'inc'
	mock_verify ssh HAS_CALLED_WITH devuser@1.2.3.4
	mock_verify start_container NEVER_CALLED
}

test_login_stopped_container() {
	mock_function is_container_running 'return 1'
	mock_function sudo 'echo "\"IPAddress\": \"1.2.3.4\",
	        \"SecondaryIPAddresses\": null,"'
	mock_function ssh
	mock_function start_container

	docker_management login img inc

	mock_verify is_container_running HAS_CALLED_WITH 'inc'
	mock_verify start_container HAS_CALLED_WITH 'img' 'inc'
	mock_verify sudo HAS_CALLED_WITH docker inspect 'inc'
	mock_verify ssh HAS_CALLED_WITH devuser@1.2.3.4
}

test_shall_stop_before_update() {
	mock_function stop_container
	mock_function docker_tool
	mock_function sudo

	docker_management update img inc ver
	
	mock_verify stop_container HAS_CALLED_WITH 'inc'
	mock_verify docker_tool HAS_CALLED_WITH retain 'img' 'ver' 
}

test_shall_update_tag_file_after_update() {
	mock_function stop_container
	mock_function docker_tool
	mock_function sudo 'set_global_var tag $(cat)'

	docker_management update test/img inc ver

	mock_verify sudo HAS_CALLED_WITH tee /var/lib/dcs/img/tag
	assertEquals ver "$(get_global_var tag)"
}

. $SHUNIT2_BIN

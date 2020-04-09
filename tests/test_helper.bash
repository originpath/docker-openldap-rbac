setup() {
	IMAGE_NAME="$NAME:$VERSION"
}

build_image() {
	#disable outputs
	docker build -t $IMAGE_NAME $BATS_TEST_DIRNAME/../image &> /dev/null
}

run_image() {
	CONTAINER_ID=$(docker run $@ -d $IMAGE_NAME --copy-service -c "/container/service/slapd/test.sh" $EXTRA_DOCKER_RUN_FLAGS)
	CONTAINER_IP=$(get_container_ip_by_cid $CONTAINER_ID)
}

get_container_ip_by_cid() {
	local IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $1)
	echo "$IP"
}


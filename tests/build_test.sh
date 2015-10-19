echo running tests for tolmark-gulp
UUID=$(cat /proc/sys/kernel/random/uuid)

pass "unable to start the $VERSION container" docker run --privileged=true -d --name $UUID nanobox/build-tolmark-gulp sleep 365d

defer docker kill $UUID

pass "Failed to create /opt/code directory" docker exec $UUID mkdir -p /opt/code

pass "Failed to create /code directory" docker exec $UUID mkdir -p /code

pass "Failed to copy test project" docker exec $UUID cp -r /opt/tests/sample-tolmark-gulp/ /opt/code

pass "Failed to run build script" docker exec $UUID bash -c "cd /opt/engines/tolmark-gulp/bin; ./build '$(payload default-build)'"
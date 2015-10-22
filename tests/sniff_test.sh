echo running tests for tolmark-gulp
UUID=$(cat /proc/sys/kernel/random/uuid)

pass "unable to start the $VERSION container" docker run --privileged=true -d --name $UUID nanobox/build-tolmark-gulp sleep 365d

defer docker kill $UUID

pass "unable to create code folder" docker exec $UUID mkdir -p /opt/code

fail "Detected something when there shouldn't be anything" docker exec $UUID bash -c "cd /opt/engines/tolmark-gulp/bin; ./sniff /opt/code"

pass "unable to remove code folder" docker exec $UUID rm -rf /opt/code

pass "Failed to copy test project" docker exec $UUID cp -r /opt/tests/sample-tolmark-gulp/ /opt/code

pass "Failed to detect tolmark-gulp" docker exec $UUID bash -c "cd /opt/engines/tolmark-gulp/bin; ./sniff /opt/code"
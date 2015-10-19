echo running tests for tolmark-gulp
UUID=$(cat /proc/sys/kernel/random/uuid)

pass "unable to start the $VERSION container" docker run --privileged=true -d --name $UUID nanobox/build-tolmark-gulp sleep 365d

defer docker kill $UUID

pass "Failed to run cleanup script" docker exec $UUID bash -c "cd /opt/engines/tolmark-gulp/bin; ./cleanup '$(payload default-cleanup)'"
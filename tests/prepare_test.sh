echo running tests for tolmark-gulp
UUID=$(cat /proc/sys/kernel/random/uuid)

pass "unable to start the $VERSION container" docker run --privileged=true -d --name $UUID nanobox/build-tolmark-gulp sleep 365d

defer docker kill $UUID

pass "create db dir for pkgsrc" docker exec $UUID mkdir -p /data/var/db

pass "create dir for environment variables" docker exec $UUID mkdir -p /data/etc/env.d 

pass "Failed to update pkgsrc" docker exec $UUID /data/bin/pkgin up -y

pass "unable to create code folder" docker exec $UUID mkdir -p /opt/code

pass "Failed to copy test project" docker exec $UUID cp -r /opt/tests/sample-tolmark-gulp/* /opt/code

pass "Failed to run prepare script" docker exec $UUID bash -c "cd /opt/engines/tolmark-gulp/bin; PATH=/data/sbin:/data/bin:\$PATH ./prepare '$(payload default-prepare)'"
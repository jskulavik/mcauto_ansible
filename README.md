**Procedure**

1. cat ~/.ssh/public_key.pub > authorized_keys

2. rm -f  ~/.ssh/known_hosts*

3. docker build -t ansible-host .

4. docker run -d \
    --name node1 \
    --privileged \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --tmpfs /run \
    --tmpfs /run/lock \
    -p 2222:22 \
    ansible-host
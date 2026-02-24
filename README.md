**Procedure**

docker build -t ansible-host .

docker run -d \
  --name node1 \
  --privileged \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --tmpfs /run \
  --tmpfs /run/lock \
  -p 2222:22 \
  ansible-host
# ROS 2 bag recorder container

This is a passive infrastructure container for recording the Nissan sensor ROS
2 topics. The container stays running, but it only records when
`record_dataset` is invoked. Bags are written directly to a bind-mounted host
directory, so replacing the container does not remove recorded data.

Run the commands from `/mnt/nvme/Projects`.

## Build

```bash
docker build \
  -f omni_onboard_platform/rosbag_recorder/Dockerfile \
  -t ros2bag-recorder:humble \
  .
```

## Create the host output directory

```bash
mkdir -p /mnt/nvme/Projects/rosbag_data
```

## Run

```bash
docker run -d \
  --name ros2bag_recorder \
  --hostname nissan-rosbag-recorder \
  --restart unless-stopped \
  --network host \
  --ipc host \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp/rosbag_recorder \
  -e ROS_DOMAIN_ID=0 \
  -e RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
  -e PATH=/opt/rosbag_recorder/scripts:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -v /mnt/nvme/Projects/rosbag_data:/data/rosbags:rw \
  -v /mnt/nvme/Projects/omni_onboard_platform/rosbag_recorder/scripts:/opt/rosbag_recorder/scripts:ro \
  ros2bag-recorder:humble
```

## Record

Start a recording with an automatically generated UTC timestamp:

```bash
docker exec -it ros2bag_recorder record_dataset
```

Or supply a single directory name:

```bash
docker exec -it ros2bag_recorder record_dataset dataset
```

Press Ctrl-C once to stop the recorder cleanly. The resulting bag appears on
the host at `/mnt/nvme/Projects/rosbag_data/<bag-name>`.

The container runs as the current host user so that recordings remain writable
and removable without `sudo`.

The helper records the topics defined in its host-side `topics=(...)` array,
including the configured GNSS, radar, ZED, IMU, and transform streams.

### Change the topic list without rebuilding

Edit the `topics=(...)` array in the host file:

```text
/mnt/nvme/Projects/omni_onboard_platform/rosbag_recorder/scripts/record_dataset
```

The complete host `scripts` directory is mounted read-only at
`/opt/rosbag_recorder/scripts`, and that directory is first on the container's
`PATH`. Every new `record_dataset` invocation therefore reads the latest saved
host script. You do not need to rebuild the image or restart the container for
topic-only changes.

Check the edited script before recording:

```bash
bash -n /mnt/nvme/Projects/omni_onboard_platform/rosbag_recorder/scripts/record_dataset
docker exec ros2bag_recorder bash -c \
  'command -v record_dataset && bash -n "$(command -v record_dataset)"'
```

Rebuild the image only when a newly added topic uses a message package that is
not already installed in the recorder, when a custom message definition
changes, or when the Dockerfile itself changes.

The image installs `zed_msgs` and builds the local
`radar_conti_srr308_msgs` interface package. Both are required for rosbag2 to
subscribe to the two custom message types, even though topic discovery alone
works without them.

## Check discovery and storage

```bash
docker exec ros2bag_recorder bash -c \
  'source /opt/ros/humble/setup.bash && ros2 topic list'

docker inspect ros2bag_recorder --format \
  '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
```

#!/bin/bash
set -e

ROS_DISTRO=${ROS_DISTRO:-humble}
ROSBAG_OUTPUT_DIR=${ROSBAG_OUTPUT_DIR:-/data/rosbags}

if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
  # shellcheck disable=SC1090
  source "/opt/ros/${ROS_DISTRO}/setup.bash"
else
  echo "ROS 2 setup file not found for ${ROS_DISTRO}" >&2
  exit 1
fi

if [ -f "/opt/rosbag_ws/install/setup.bash" ]; then
  # shellcheck disable=SC1091
  source /opt/rosbag_ws/install/setup.bash
else
  echo "Radar message overlay not found: /opt/rosbag_ws/install/setup.bash" >&2
  exit 1
fi

if [ ! -d "${ROSBAG_OUTPUT_DIR}" ]; then
  echo "Rosbag output directory not found: ${ROSBAG_OUTPUT_DIR}" >&2
  echo "Mount a host directory at this path before starting the container." >&2
  exit 1
fi

if [ ! -w "${ROSBAG_OUTPUT_DIR}" ]; then
  echo "Rosbag output directory is not writable: ${ROSBAG_OUTPUT_DIR}" >&2
  exit 1
fi

if [ -n "${HOME:-}" ]; then
  mkdir -p "${HOME}/.ros"
fi

export ROS_DOMAIN_ID
export RMW_IMPLEMENTATION
export ROSBAG_OUTPUT_DIR

echo "ROS 2 bag recorder infrastructure"
echo "ROS distro: ${ROS_DISTRO}"
echo "ROS_DOMAIN_ID: ${ROS_DOMAIN_ID}"
echo "RMW_IMPLEMENTATION: ${RMW_IMPLEMENTATION}"
echo "Host-backed output path: ${ROSBAG_OUTPUT_DIR}"
echo "radar_conti_srr308_msgs: $(ros2 pkg prefix radar_conti_srr308_msgs)"
echo "zed_msgs: $(ros2 pkg prefix zed_msgs)"
echo "Run 'docker exec -it ros2bag_recorder record_dataset' to start recording."

exec "$@"

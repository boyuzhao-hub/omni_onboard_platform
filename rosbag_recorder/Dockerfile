ARG ROS_DISTRO=humble
ARG IMAGE_NAME=ros:${ROS_DISTRO}-ros-base-jammy

FROM ${IMAGE_NAME}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG ROS_DISTRO=humble

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=${ROS_DISTRO} \
    ROS_DOMAIN_ID=0 \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
    ROSBAG_OUTPUT_DIR=/data/rosbags \
    PATH=/opt/rosbag_recorder/scripts:${PATH}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      python3-colcon-common-extensions \
      ros-${ROS_DISTRO}-ament-cmake \
      ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
      ros-${ROS_DISTRO}-rosbag2 \
      ros-${ROS_DISTRO}-rosidl-default-generators \
      ros-${ROS_DISTRO}-zed-msgs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rosbag_ws/src

COPY radar_ros2_ws/src/srr308_radar_driver/src/srr-308/radar_conti_srr308_msgs/ \
     radar_conti_srr308_msgs/

WORKDIR /opt/rosbag_ws

RUN source "/opt/ros/${ROS_DISTRO}/setup.bash" && \
    colcon build \
      --packages-select radar_conti_srr308_msgs \
      --event-handlers console_direct+ \
      --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF && \
    rm -rf build log

COPY omni_onboard_platform/rosbag_recorder/docker/entrypoint.sh \
     /sbin/rosbag_recorder_entrypoint.sh
COPY omni_onboard_platform/rosbag_recorder/scripts/record_dataset \
     /usr/local/bin/record_dataset

RUN chmod 755 \
      /sbin/rosbag_recorder_entrypoint.sh \
      /usr/local/bin/record_dataset

WORKDIR ${ROSBAG_OUTPUT_DIR}

ENTRYPOINT ["/sbin/rosbag_recorder_entrypoint.sh"]
CMD ["sleep", "infinity"]

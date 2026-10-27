# Omni Onboard Platform

**A Heterogeneous Onboard Platform for Real-Time Omnidirectional Perception and Ego-State Estimation**

Omni Onboard Platform is the main integration and documentation repository for
an onboard ROS 2 system installed on a 2012 Nissan LEAF. The platform combines
an x86 vehicle computer with an NVIDIA Jetson AGX Orin sensor computer and
connects cameras, radars, GNSS receivers, an IMU, and vehicle CAN data in one
distributed system.

This repository is the entry point to the complete project. The individual
hardware drivers remain independently versioned in sibling ROS 2 workspaces.

## Thesis and demo

- &#128214; **Thesis:** Zhao, B. (2026). [*A Heterogeneous Onboard Platform for Real-Time Omnidirectional Perception and Ego-State Estimation*](https://research.tue.nl/en/publications/a-heterogeneous-onboard-platform-for-real-time-omnidirectional-pe/). Eindhoven University of Technology.
- &#9654;&#65039; **[Demo video](https://youtu.be/LDkqcESuo-4?si=YXt7zGQ5bTY7jOqf)** — Watch on YouTube or click the preview below.

[![Watch the Omni Onboard Platform demo](https://img.youtube.com/vi/LDkqcESuo-4/hqdefault.jpg)](https://youtu.be/LDkqcESuo-4?si=YXt7zGQ5bTY7jOqf)

## System overview

The platform divides work between two onboard computers:

| Computer | Architecture | Primary role |
|---|---|---|
| Advantech ARK-2251 | x86-64 | Nissan LEAF CAN acquisition and vehicle-state signals |
| Jetson AGX Orin 64 GB on the Syslogic platform | ARM64 with NVIDIA GPU | Camera, radar, GNSS, and IMU acquisition and processing |

Both computers run ROS 2 Humble. ROS messages are exchanged through CycloneDDS
over the onboard Ethernet network.

![Hardware architecture: sensors, compute units, and vehicle connections](./docs/assets/Hardware_Architecture.png)

The Syslogic RML A4AGX64 houses the Jetson sensor computer. Four ZED X stereo
cameras connect over GMSL2, while the Continental radars and SC13S IMU use
CAN. Two GNSS antennas support positioning and timing through the u-blox
receivers. The ARK-2251 acquires vehicle CAN signals and exchanges ROS 2
messages with the sensor computer over Ethernet.

### Electrical and data connections

The topology below complements the hardware overview with the electrical and
data connections between the vehicle, onboard computers, and sensors.

![Hardware topology: electrical and data connections](./docs/assets/Hardware_Topology.drawio.svg)

## Communication and time synchronization

CycloneDDS provides ROS 2 discovery and data transport between the x86 and
ARM64 computers. The supplied [`cyclonedds.xml`](./cyclonedds.xml) applies to any DDS domain,
disables multicast, selects the Jetson/Syslogic-side `lan2`
interface, and configures the ARK-2251 at `192.168.100.2` as a discovery peer.
Interface names and peer addresses are deployment-specific and must be checked
on each computer. The Compose services set `ROS_DOMAIN_ID=0`.

Clock synchronization is handled separately from DDS:

1. GNSS supplies UTC through NMEA and PPS.
2. Chrony disciplines the Jetson/Syslogic system clock.
3. The Jetson/Syslogic computer acts as the PTP master.
4. The ARK-2251 acts as the PTP slave.
5. `ptp4l` synchronizes the network hardware clocks and `phc2sys` synchronizes
   the Linux system clock.

This allows sensor and vehicle messages produced on different computers to use
a common time base. See the
[PTP configuration guide](./docs/wiki/ptp_multi_cameras_config.md) for the
current setup.

![Time synchronization across GNSS, onboard computers, and sensors](./docs/assets/Time_Synchronization.svg)

The diagram distinguishes synchronization pulses from software timestamping.
A shared host clock provides a common timestamp reference; sensor capture
alignment and end-to-end timing accuracy still require validation.

## Hardware

| Category | Hardware | Quantity | Documentation |
|---|---|---:|---|
| Vehicle | Nissan LEAF MY2012 | 1 | [Nissan LEAF OBD-II manual](https://leaf-obd.readthedocs.io/en/latest/) |
| Compute | Jetson AGX Orin 64 GB | 1 | [Board specification](./docs/datasheets/Computer_Jetson_AGX_Orin_Module_Carrier_Board_Specification.pdf) |
| Compute | Advantech ARK-2251 | 1 | [Datasheet](./docs/datasheets/Computer_ARK_2251_Datasheet.pdf) |
| Vision | ZED X stereo camera with integrated IMU | 4 | [Datasheet](./docs/datasheets/Sensor_ZED_X_Datasheet.pdf) |
| Radar | Continental SRR308-21 short-range radar | 4 | [Datasheet](./docs/datasheets/Sensor_SRR308_Datasheet.pdf)<br>[Interface specification](./docs/datasheets/Sensor_ARS_40X_SRR308_Interface.pdf)<br>[Short description](./docs/datasheets/Sensor_SRR308_Short_Description.pdf) |
| Inertial | Continental SC13S six-degree-of-freedom IMU | 1 | [Datasheet](./docs/datasheets/Sensor_IMU_SC13S.pdf) |
| Positioning and timing | u-blox ZED-F9 RTK GNSS | 2 | [Syslogic GNSS guide](./docs/datasheets/Sensor_GNSS_%20accessing_GNSS_on_Syslogic_systems.pdf) |

## Coordinate system and sensor frames

![Vehicle coordinate system and camera, radar, and GNSS frame locations](./docs/assets/Coordinate_System.png)

The vehicle reference frame, `base_link`, is located at the center of the rear
axle. The diagram identifies the sensor frames around the vehicle:

| Sensor group | Frames |
|---|---|
| Cameras | `front_camera_link`, `rear_camera_link`, `left_camera_link`, `right_camera_link` |
| Radars | `radar_front_left_link`, `radar_front_right_link`, `radar_rear_left_link`, `radar_rear_right_link` |
| GNSS | `front_gnss_link`, `rear_gnss_link` |

The `vehicle_description` package defines the vehicle URDF and sensor transforms,
which are published by `robot_state_publisher`. Use the configured URDF transforms
for sensor offsets and orientations; the figure is a layout reference, not a
source of calibration measurements.

## Software components

![Software architecture: host services, driver containers, ROS 2 transport, and applications](./docs/assets/Software_Architecture.png)

The architecture separates host services (JetPack or Ubuntu, Docker, and PTP),
sensor and vehicle driver containers, and downstream ROS 2 applications.
CycloneDDS carries messages between the computers, while the bag recorder
captures selected streams for offline analysis. The application layer shows
intended uses, including object detection, trajectory prediction, vehicle-state
estimation, and dynamic calibration. See [Deployment status](#deployment-status)
for the services currently included in this repository's Compose configuration.

The source code is organized as multiple sibling ROS 2 workspaces under the
local project root, `/mnt/nvme/Projects`.

| Workspace and package | Target | Responsibility | Repository |
|---|---|---|---|
| `nissan_ros2_ws/src/nissan_leaf_can_driver_ros2` | ARK-2251 | SocketCAN bridge, Nissan CAN decoding, and vehicle dynamics messages | [nissan_leaf_can_driver_ros2](https://github.com/boyuzhao-hub/nissan_leaf_can_driver_ros2) |
| `nissan_ros2_ws/src/vehicle_description` | Integration | Nissan URDF, sensor frames, and robot-state publisher | Currently stored as a local package |
| `imu_ros2_ws/src/sc13s_imu_driver` | Jetson | SC13S CAN decoding, raw IMU data, raw CAN frames, and diagnostics | [sc13s_imu_driver](https://github.com/boyuzhao-hub/sc13s_imu_driver) |
| `radar_ros2_ws/src/srr308_radar_driver` | Jetson | Four-radar CAN acquisition, configuration, visualization, and tracking components | [srr308_radar_driver](https://github.com/boyuzhao-hub/srr308_radar_driver) |
| `ublox_ros2_ws/src/ublox_dgnss_ros2` | Jetson | Dual-GNSS USB acquisition, moving-base configuration, RTK data, and high-precision fixes | [ublox_dgnss_ros2](https://github.com/boyuzhao-hub/ublox_dgnss_ros2) |
| `zed_ros2_ws/src/zed-ros2-wrapper` | Jetson | ZED X camera acquisition and custom multi-camera launch/URDF support | [zed-ros2-wrapper](https://github.com/boyuzhao-hub/zed-ros2-wrapper) |
| `zed_ros2_ws/src/zed-ros2-description` | Jetson | Upstream ZED camera descriptions | [zed-ros2-description](https://github.com/stereolabs/zed-ros2-description) |
| `omni_onboard_platform/rosbag_recorder` | Integration | Passive, host-backed recording of selected GNSS, radar, ZED, IMU, and transform streams | Local infrastructure component, this repository |

## Current project layout

```text
/mnt/nvme/Projects/
|-- omni_onboard_platform/                 # Main entry repository
|   |-- README.md
|   |-- cyclonedds.xml                     # Inter-computer DDS configuration
|   |-- docker-compose.yml                # Current integration services
|   |-- rosbag_recorder/                   # Persistent rosbag infrastructure
|   `-- docs/
|       |-- assets/                        # Architecture and sensor diagrams
|       |-- datasheets/                    # Hardware specifications and manuals
|       `-- wiki/                          # Project knowledge base
|-- nissan_ros2_ws/
|   `-- src/
|       |-- nissan_leaf_can_driver_ros2/    # Vehicle CAN stack
|       `-- vehicle_description/           # Vehicle URDF and static frames
|-- imu_ros2_ws/
|   `-- src/sc13s_imu_driver/
|-- radar_ros2_ws/
|   `-- src/srr308_radar_driver/
|-- ublox_ros2_ws/
|   `-- src/ublox_dgnss_ros2/
|-- rosbag_data/                           # Host-backed recorded datasets
`-- zed_ros2_ws/
    `-- src/
        |-- zed-ros2-description/
        |-- zed-ros2-examples/
        `-- zed-ros2-wrapper/
```

The workspaces are siblings of this repository; they are not contained in an
`omni_onboard_platform/src` monorepo.

## Deployment status

The current [`docker-compose.yml`](./docker-compose.yml) contains two services:

- `core_state`: builds and launches `vehicle_description` and
  `robot_state_publisher`.
- `sc13s_imu`: builds and launches the SC13S IMU driver on host SocketCAN
  interface `can1`.

The standalone [`rosbag_recorder`](./rosbag_recorder/README.md) container is
deployed separately from Compose. It remains idle until a recording is started
with `docker exec`, and bind-mounts `/mnt/nvme/Projects/rosbag_data` so bags
survive container replacement.

Radar, GNSS, ZED camera, and Nissan CAN services are maintained in their
component workspaces but have not yet been added to the integration Compose
file. Likewise, the repository currently provides the measurements required
for ego-state estimation, but a system-level fusion estimator is not yet part
of the integration repository.

> **Compose path migration:** `docker-compose.yml` was moved from
> `/mnt/nvme/Projects` into this repository. Its workspace references still use
> the former relative paths. Before launching from `omni_onboard_platform`,
> change component references such as `./imu_ros2_ws/...` to
> `../imu_ros2_ws/...`; the `core_state` image also needs the parent project
> directory as its Docker build context because it copies both
> `vehicle_description` and `zed-ros2-description`.

## Prerequisites

### Both computers

- Ubuntu 22.04 LTS
- ROS 2 Humble
- `rmw_cyclonedds_cpp`
- An Ethernet connection configured for ROS 2 and PTP
- LinuxPTP and Chrony for clock synchronization

### Jetson sensor computer

- JetPack 6.2.2
- CUDA 12.6
- A compatible ZED SDK
- SocketCAN interfaces configured for the radar and SC13S buses
- USB access and udev rules for the GNSS receivers

### ARK-2251 vehicle computer

- A configured SocketCAN interface for the Nissan LEAF CAN bus
- Network access to the Jetson/Syslogic CycloneDDS participant

## Knowledge base

### Sensors, CAN, and synchronization

- [CAN frame structure](./docs/wiki/can_frame_structure.md)
- [Understanding DBC files](./docs/wiki/understand_dbc_file.md)
- [RTK GNSS and u-blox configuration](./docs/wiki/rtk_gnss.md)
- [PTP clock synchronization](./docs/wiki/ptp_multi_cameras_config.md)
- [Continental SRR308 configuration handbook](./docs/wiki/srr308_configuration_handbook.md)

### ROS 2 and deployment

- [ROS 2 message serialization, RMW, and DDS](./docs/wiki/ros2_message_serialization.md)
- [Writing a URDF](./docs/wiki/write_a_urdf.md)
- [Writing a Dockerfile](./docs/wiki/write_a_dockerfile.md)
# Precision Time Protocol (PTP)

The Precision Time Protocol (PTP) is an IEEE standard used to synchronize the clocks of multiple devices on an Ethernet network. It designates one device as the master clock and others as slaves, which periodically synchronize and adjust to the master clock. This ensures that all devices (e.g., cameras or sensors) in the local network publish data frames with timestamps referenced to the exact same time source.

## Hardware vs. Software PTP

Hardware support in **Network Interface Controllers (NICs)** allows PTP to account for delays in message transfer, greatly improving the accuracy of time synchronization. To achieve the best possible precision, it is recommended that all network components between PTP clocks are enabled for hardware PTP.

* **Hardware PTP:** The NIC utilizes its own built-in clock to timestamp received and transmitted PTP messages. This onboard clock is synchronized with the PTP master, and the computer's system clock is then synchronized with the PTP hardware clock on the NIC. This provides superior accuracy because the NIC stamps packets at the exact hardware level as they are sent or received.
* **Software PTP:** The operating system's system clock is used to timestamp PTP messages and is synchronized directly with the PTP master. This introduces slight delays and variability because it requires additional packet processing by the OS.

Given these advantages, hardware PTP is an ideal solution for sensor fusion scenarios, seamlessly integrating vehicles with various computers and sensors.

## System Architecture

In this specific design, the synchronization flow is as follows:

* **RTK GNSS (Grandmaster Clock):** Retrieves UTC time through PPS and NMEA streams directly from satellites.
* **Syslogic Computer (PTP Master):** Obtains the PPS signal from the GNSS. Simultaneously, it broadcasts precise time over the Ethernet using `ptp4l`.
* **Advantech ARK2251 (PTP Slave):** Receives the time from the Syslogic computer via its Ethernet port using `ptp4l`. It then uses `phc2sys` to synchronize the PTP hardware clock to its local Linux system clock.

## Configuration Guide

### 1. On Syslogic (Master)
First, synchronize the system time with the satellite via the u-blox antenna using `chrony`, which can be found [here](./rtk_gnss.md)  Then, activate the PTP Master:

```bash
# Install required packages
sudo apt update
sudo apt install linuxptp ethtool

# Start PTP Master on eth0 (Hardware timestamping enabled)
sudo ptp4l -i eth0 -m -H -l 6
```

### On ARK2251 (Slave)
Install the PTP utility, configure it to receive the time, and sync it to the local system clock:

```bash
# Install required packages
sudo apt update
sudo apt install linuxptp

# Start PTP Slave on eth0 to receive time from Syslogic (-s flag indicates slave mode)
sudo ptp4l -i eth0 -m -H -s -l 6

# Synchronize the PTP hardware clock to the Linux system clock
sudo phc2sys -s eth0 -c CLOCK_REALTIME -w -m
```
# How RTK GNSS Delivers Superior Performance

Real-Time Kinematic (RTK) GNSS significantly enhances positioning precision and time synchronization accuracy compared to standard GNSS. By utilizing the carrier phase of the satellite signal alongside the information content, it achieves centimeter-level positioning and highly accurate microsecond-level timing.

## Configure RTK GNSS

**GNSS Model:** u-blox ZED-F9

*Note: Syslogic provides a comprehensive manual for setting up the GNSS on their systems, which can be found [here](/docs/datasheets/Sensor_GNSS_%20accessing_GNSS_on_Syslogic_systems.pdf).*

### 1. Access the GNSS Data

The GNSS receiver typically provides two streams of NMEA data via serial interfaces, for this setup, they are `ACM0` and `ACM1`.

To inspect the raw data streams, use the following commands:
```bash
cat /dev/ttyACM0

cat /dev/ttyACM1
```

**Key NMEA Sentences to look for:**
* `$GNRMC` (Recommended Minimum Specific GNSS Data): Includes UTC Time, Longitude, Latitude, Date, etc.
* `$GNGGA` (Global Positioning System Fix Data): Includes the status of the position fix, number of satellites in view, altitude, etc.

> **Pro Tip:** For advanced configuration and real-time monitoring, it is highly recommended to use **u-center**, a Windows-based evaluation software provided by u-blox.

### 2. Time Synchronization with Chrony

To use the GNSS receiver as a precision time source for your system, you need to configure `chrony` to read the NMEA stream and the PPS (Pulse Per Second) signal.

**Step 1: Assign user permissions**
Make sure you have the `chrony` service installed. Grant the `chrony` user permission to read the u-blox serial port by adding it to the `dialout` group:

```bash
sudo usermod -a -G dialout _chrony
```

**Step 2: Modify the configuration**
Open the chrony configuration file:
```bash
sudo usermod -a -G dialout _chrony
```

```bash
# ======================================================================
# u-blox ZED-F9 GNSS & PPS configurations
# ======================================================================
refclock NMEA /dev/ttyACM0 baud 115200 delay 0.1 refid NMEA noselect
refclock PPS /dev/pps0 lock NMEA refid PPS prefer
```

**Step 3: Restart and verify the service** 
Restart the chrony service to apply the new configurations:

```bash
sudo systemctl restart chrony
```
from pymavlink import mavutil


class Drone:

    def __init__(self, connection="/dev/ttyACM0", baud=115200):

        self.master = mavutil.mavlink_connection(connection, baud=baud)

        # GPS
        self.gps_fix = 0
        self.satellites = 0
        self.latitude = 0.0
        self.longitude = 0.0

        # Position
        self.altitude = 0.0
        self.relative_altitude = 0.0
        self.groundspeed = 0.0

        # Attitude
        self.roll = 0.0
        self.pitch = 0.0
        self.yaw = 0.0

        # Flight state
        self.armed = False
        self.flight_mode = ""

        # Battery
        self.battery_voltage = 0.0
        self.battery_current = 0.0
        self.battery_remaining = -1

        # RC
        self.rc_channel_15 = 0
        self.rc15_last_low = 0

    def connect(self):

        print("Waiting for heartbeat...")

        self.master.wait_heartbeat()

        print("Connected!")

        print(f"System: {self.master.target_system}")

        print(f"Component: {self.master.target_component}")

    def request_messages(self):

        # GPS_RAW_INT
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
            0,
            24,  # GPS_RAW_INT
            1_000_000,  # 1 Hz
            0,
            0,
            0,
            0,
            0,
        )

        # GLOBAL_POSITION_INT
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
            0,
            33,  # GLOBAL_POSITION_INT
            200_000,  # 5 Hz
            0,
            0,
            0,
            0,
            0,
        )

        # ATTITUDE
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
            0,
            30,  # ATTITUDE
            200_000,  # 5 Hz
            0,
            0,
            0,
            0,
            0,
        )

        # BATTERY_STATUS
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
            0,
            147,  # BATTERY_STATUS
            1_000_000,  # 1 Hz
            0,
            0,
            0,
            0,
            0,
        )

        # VFR_HUD
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
            0,
            74,  # VFR_HUD
            500_000,  # 2 Hz
            0,
            0,
            0,
            0,
            0,
        )

        # RC_CHANNELS
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
            0,
            65,  # RC_CHANNELS
            200_000,  # 5 Hz
            0,
            0,
            0,
            0,
            0,
        )

    def update(self):

        while True:
            msg = self.master.recv_match(blocking=False)

            if msg is None:
                break

            msg_type = msg.get_type()

            # -------------------------
            # GPS
            # -------------------------

            if msg_type == "GPS_RAW_INT":

                self.gps_fix = msg.fix_type

                self.satellites = msg.satellites_visible

                self.latitude = msg.lat / 1e7

                self.longitude = msg.lon / 1e7

            # -------------------------
            # GLOBAL POSITION
            # -------------------------

            elif msg_type == "GLOBAL_POSITION_INT":

                self.altitude = msg.alt / 1000

                self.relative_altitude = msg.relative_alt / 1000

                self.groundspeed = ((msg.vx**2 + msg.vy**2) ** 0.5) / 100

            # -------------------------
            # ATTITUDE
            # -------------------------

            elif msg_type == "ATTITUDE":

                self.roll = msg.roll

                self.pitch = msg.pitch

                self.yaw = msg.yaw

            # -------------------------
            # HEARTBEAT
            # -------------------------

            elif msg_type == "HEARTBEAT":

                self.armed = bool(
                    msg.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED
                )

                self.flight_mode = mavutil.mode_string_v10(msg)

            # -------------------------
            # BATTERY
            # -------------------------

            elif msg_type == "BATTERY_STATUS":

                if msg.voltages[0] != 65535:

                    self.battery_voltage = msg.voltages[0] / 1000

                self.battery_current = msg.current_battery / 100

                self.battery_remaining = msg.battery_remaining

            # -------------------------
            # RC CHANNELS
            # -------------------------

            elif msg_type == "RC_CHANNELS":

                self.rc_channel_15 = msg.chan15_raw

    def gps_ready(self):
        return self.gps_fix >= 3

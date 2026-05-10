return {
    auto_mount = true,

    devices = {
        {
            peripheral = "speaker",
            path = "/dev/speaker0"
        },
        {
            peripheral = "monitor",
            path = "/dev/monitor0"
        },
        {
            peripheral = "modem",
            path = "/dev/modem0"
        },
        {
            peripheral = "drive",
            path = "/dev/drive0"
        }
    }
}

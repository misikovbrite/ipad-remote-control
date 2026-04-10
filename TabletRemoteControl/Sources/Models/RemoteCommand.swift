import Foundation

enum RemoteKey: String {
    // Navigation
    case up = "UP"
    case down = "DOWN"
    case left = "LEFT"
    case right = "RIGHT"
    case enter = "ENTER"
    case back = "BACK"
    case home = "HOME"
    case menu = "MENU"

    // Power
    case power = "POWER"
    case powerOn = "POWER_ON"
    case powerOff = "POWER_OFF"

    // Volume
    case volumeUp = "VOLUME_UP"
    case volumeDown = "VOLUME_DOWN"
    case mute = "MUTE"

    // Channels
    case channelUp = "CHANNEL_UP"
    case channelDown = "CHANNEL_DOWN"

    // Playback
    case play = "PLAY"
    case pause = "PAUSE"
    case stop = "STOP"
    case rewind = "REWIND"
    case fastForward = "FAST_FORWARD"

    // Input
    case source = "SOURCE"
    case hdmi1 = "HDMI1"
    case hdmi2 = "HDMI2"

    // Numbers
    case num0 = "0"
    case num1 = "1"
    case num2 = "2"
    case num3 = "3"
    case num4 = "4"
    case num5 = "5"
    case num6 = "6"
    case num7 = "7"
    case num8 = "8"
    case num9 = "9"

    // Apps
    case netflix = "NETFLIX"
    case youtube = "YOUTUBE"
    case prime = "PRIME_VIDEO"
}

struct MouseEvent {
    let dx: Float
    let dy: Float
    let isClick: Bool
    let isScroll: Bool
    let scrollDelta: Float
}

import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: menu

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "#4d0c0c0c"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: Qt.quit()

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: Math.max(24, parent.width * 0.045)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            Repeater {
                model: [
                    { icon: "shutdown.png", action: ["systemctl", "poweroff"] },
                    { icon: "reboot.png", action: ["systemctl", "reboot"] },
                    { icon: "hibernate.svg", action: ["bash", Quickshell.shellPath("hibernate.sh")] },
                    { icon: "logout.png", action: ["hyprctl", "dispatch", "exit"] }
                ]

                delegate: Rectangle {
                    id: circle
                    required property var modelData
                    width: 100
                    height: width
                    radius: width / 2
                    color: button.containsMouse ? "#4dffffff" : "#660c0c0c"

                    Behavior on color {
                        ColorAnimation { duration: 160 }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        fillMode: Image.PreserveAspectFit
                        source: Qt.resolvedUrl("icons/" + circle.modelData.icon)
                    }

                    MouseArea {
                        id: button
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(circle.modelData.action)
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }
}

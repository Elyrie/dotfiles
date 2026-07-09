import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

Rectangle {
    id: root

    property alias showInfo: info.visible

    anchors.fill: parent
    color: "transparent"

    Rectangle {
        id: info

        anchors.fill: parent
        anchors.margins: 70
        color: "transparent"

        Process {
            id: batProc
            command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
            running: true
            stdout: SplitParser {
                onRead: data => {
                    const percent = parseInt(data);
                    if (percent < 40)
                        bat.source = "/home/vvalkila/.config/quickshell/assets/battery_low.svg";
                    else if (percent < 80)
                        bat.source = "/home/vvalkila/.config/quickshell/assets/battery_mid.svg";
                    else
                        bat.source = "/home/vvalkila/.config/quickshell/assets/battery_full.svg";
                }
            }
        }
        Image {
            id: bat
            anchors.right: parent.right
            source: "/home/vvalkila/.config/quickshell/assets/battery_full.svg"
            sourceSize.width: 150
            opacity: 0.7
        }

        Process {
            id: dateProc
            command: ["date", "+%H:%M"]
            running: true
            stdout: SplitParser {
                onRead: data => timetxt.text = data
            }
        }
        Text {
            id: timetxt
            text: "00:00"
            color: "#ffffff"
            font.pointSize: 64
            font.family: "monospace"
            font.bold: true
            font.italic: true
            verticalAlignment: Text.AlignVCenter
            opacity: 0.7
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: () => {
                batProc.running = true;
                dateProc.running = true;
            }
        }
    }

    AnimatedImage {
        id: reflection
        source: "/home/vvalkila/.config/quickshell/assets/reflection.webp"
        anchors.fill: parent
        fillMode: Image.FillMode.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        source: reflection
        anchors.fill: reflection
        blurEnabled: true
        blur: 1
        blurMultiplier: 5
        opacity: 0.15
        contrast: 0.1
        saturation: -0.5
        brightness: -0.5
    }
}

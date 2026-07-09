import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell.Io
import "./InfoOverlayComponent.qml"

Rectangle {
    id: root
    required property LockContext context

    color: "#000"

    InfoOverlayComponent {}

    Rectangle {
        id: container
        color: "transparent"
        anchors.fill: parent
        visible: false

        ColumnLayout {
            anchors {
                // Keep the label centered; field grows rightward
                left: parent.left
                leftMargin: parent.width * 0.30
                top: parent.verticalCenter
            }

            RowLayout {
                Text {
                    id: passwordLabel
                    text: "password:"
                    color: "white"
                    font.pointSize: 32
                    font.family: "monospace"
                    font.bold: true
                }
                TextField {
                    id: passwordBox

                    implicitWidth: Math.min(Math.max(contentWidth + padding * 2, 400), 900)
                    font.pointSize: 32
                    font.family: "monospace"
                    font.bold: true

                    padding: 10

                    focus: true
                    enabled: !root.context.unlockInProgress
                    echoMode: TextInput.Password
                    passwordCharacter: "*"
                    inputMethodHints: Qt.ImhSensitiveData

                    onTextChanged: root.context.currentText = this.text
                    onAccepted: root.context.tryUnlock()

                    color: "white"
                    cursorDelegate: Rectangle {
                        id: cursor
                        width: 20
                        color: "white"
                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: true
                            PropertyAction {
                                target: cursor
                                property: "visible"
                                value: true
                            }
                            PauseAnimation { duration: 500 }
                            PropertyAction {
                                target: cursor
                                property: "visible"
                                value: false
                            }
                            PauseAnimation { duration: 500 }
                        }
                    }
                    background: Rectangle {
                        color: "transparent"
                    }

                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            passwordBox.text = root.context.currentText;
                        }
                    }
                }
            }

            Text {
                visible: root.context.showFailure
                text: "incorrect password"
                color: "#ff6666"
                font.pointSize: 14
                font.family: "monospace"
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Image {
            id: m
            source: "/home/vvalkila/.config/quickshell/assets/m_for_masterful.png"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 30
            anchors.bottomMargin: 30
            width: 150
            fillMode: Image.PreserveAspectFit
        }
        Image {
            source: "/home/vvalkila/.config/quickshell/assets/warning_label.png"
            anchors.left: m.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 30
            anchors.bottomMargin: 30
            width: 445
            fillMode: Image.PreserveAspectFit
        }
        Image {
            source: "/home/vvalkila/.config/quickshell/assets/qvantel_logo_white.svg"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 30
            anchors.bottomMargin: 30
            width: 300
            fillMode: Image.PreserveAspectFit
        }
    }

    Image {
        id: scrcpImage
        anchors.fill: parent
        source: "/tmp/lock_screencopy.jpeg"
        visible: false
    }
    MultiEffect {
        id: scrcp
        anchors.centerIn: parent
        width: 1920
        height: 1200
        source: scrcpImage
        brightness: 0
    }

    // CRT overlay: scanlines + vignette + subtle flicker on top of everything
    ShaderEffect {
        id: crtOverlay
        anchors.fill: parent
        enabled: false          // don't consume mouse/keyboard events
        blending: true
        vertexShader: "crt_overlay.vert.qsb"
        fragmentShader: "crt_overlay.frag.qsb"

        property real time: 0
        NumberAnimation on time {
            from: 0
            to: 628.318         // 2π × 100 — long cycle so it never jumps
            duration: 60000
            loops: Animation.Infinite
            running: true
        }
    }

    Process {
        id: tvOffSound
        command: ["play", "--volume", "3", "/home/vvalkila/.config/quickshell/assets/tv_off.wav"]
        running: true
        onStarted: tvOffAnim.running = true
    }

    SequentialAnimation {
        id: tvOffAnim
        running: false

        ParallelAnimation {
            NumberAnimation {
                target: scrcp
                property: "brightness"
                to: 1
                duration: 1000
                easing.type: Easing.OutExpo
            }
            NumberAnimation {
                target: scrcp
                property: "height"
                to: 10
                duration: 500
                easing.type: Easing.OutExpo
            }
            SequentialAnimation {
                PauseAnimation { duration: 300 }
                NumberAnimation {
                    target: scrcp
                    property: "width"
                    to: 0
                    duration: 300
                    easing.type: Easing.OutExpo
                }
                PropertyAction {
                    target: scrcp
                    property: "visible"
                    value: false
                }
            }
        }

        PropertyAction {
            target: flickerSound
            property: "running"
            value: true
        }
    }

    Process {
        id: flickerSound
        command: ["play", "--volume", "3", "/home/vvalkila/.config/quickshell/assets/lights_flicker.wav"]
        running: false
        onStarted: flickerAnim.running = true
        onExited: noiseSound.running = true
    }
    // ffplay is unavailable; use sox repeat as a looping substitute
    Process {
        id: noiseSound
        command: ["play", "-q", "/home/vvalkila/.config/quickshell/assets/lights_noise.wav", "repeat", "65535"]
        running: false
    }

    SequentialAnimation {
        id: flickerAnim

        PauseAnimation { duration: 200 }
        PropertyAction {
            target: container
            property: "visible"
            value: true
        }
        PauseAnimation { duration: 100 }
        PropertyAction {
            target: container
            property: "visible"
            value: false
        }
        PauseAnimation { duration: 200 }
        PropertyAction {
            target: container
            property: "visible"
            value: true
        }
    }
}

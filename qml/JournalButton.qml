import QtQuick
import QtQuick.Controls.Basic as Basic
import org.starship.journal

Basic.Button {
    id: button
    font.family: SpaceStyle.sans
    hoverEnabled: true
    padding: 8
    leftPadding: 12
    rightPadding: 12
    spacing: 8
    implicitHeight: Math.max(36, implicitContentHeight + topPadding + bottomPadding)
    icon.width: 18
    icon.height: 18
    icon.color: enabled ? (checked ? SpaceStyle.softAccent : SpaceStyle.text) : SpaceStyle.dim
    palette.buttonText: enabled ? (checked ? SpaceStyle.softAccent : SpaceStyle.text) : SpaceStyle.dim
    background: Rectangle {
        radius: 8
        color: button.down ? "#304052" : button.checked ? "#30eac38e"
            : button.hovered ? "#263748" : button.flat ? "transparent" : SpaceStyle.raised
        border.color: button.visualFocus ? SpaceStyle.accent : button.checked ? "#70eac38e"
            : button.flat && !button.hovered ? "transparent" : SpaceStyle.line
        border.width: button.visualFocus ? 2 : 1
        opacity: button.enabled ? 1 : 0.5
    }
}

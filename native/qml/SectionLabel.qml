import QtQuick
import org.starship.journal
import QtQuick.Controls as Controls

Controls.Label {
    color: SpaceStyle.accent
    font.family: SpaceStyle.mono
    font.pointSize: (10) * 0.75
    font.letterSpacing: 1.8
    font.weight: Font.Medium
    elide: Text.ElideRight
}

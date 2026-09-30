pragma ComponentBehavior: Bound
import QtQuick
import org.starship.journal
import QtQuick.Controls as Controls
import QtQuick.Layouts

ColumnLayout {
    id: stat
    required property string label
    required property string value
    property color valueColor: SpaceStyle.text
    spacing: 7
    SectionLabel { Layout.fillWidth: true; text: stat.label; color: SpaceStyle.dim }
    Controls.Label { Layout.fillWidth: true; text: stat.value; color: stat.valueColor; font.family: SpaceStyle.sans; font.pointSize: 11.25; font.weight: Font.Medium; wrapMode: Text.WordWrap }
}

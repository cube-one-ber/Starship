pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtCore as Core
import org.kde.kirigami as Kirigami
import org.starship.journal

Kirigami.ScrollablePage {
    required property var root
    required property var backend
    id: launch
    title: "Next launch"
    padding: root.narrowTest || root.width < 810 ? 20 : 32
    AnimatedColumn {
        motionEnabled: root.motionEnabled
        width: launch.availableWidth
        spacing: Kirigami.Units.largeSpacing
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 42
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.largeSpacing
            SectionLabel { text: "02 / ON THE HORIZON"; color: SpaceStyle.dim }
            Kirigami.Heading { text: "The next chapter."; font.family: SpaceStyle.serif; font.pointSize: 31.5; color: SpaceStyle.text; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            CountdownPanel { Layout.fillWidth: true; motionEnabled: root.motionEnabled; schedule: root.schedule; scheduleState: root.scheduleState; countdown: root.countdown; busy: backend.busy; errorMessage: backend.error_message; onRefreshRequested: backend.refresh() }
            Photo { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 14; cornerRadius: SpaceStyle.radius; cornerColor: SpaceStyle.voidColor; path: "/photos/hero"; useJxl: backend.supports_jxl; motionEnabled: root.motionEnabled; description: "Starship launching from Starbase" }
            Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "Launch timing may change as vehicles are tested and prepared. Only precise launch times are used for the countdown; provisional months and quarters are not treated as confirmed dates."; wrapMode: Text.WordWrap }
        }
    }
}

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
    id: about
    title: "About Starship"
    padding: root.narrowTest || root.width < 810 ? 20 : 32
    AnimatedColumn {
        motionEnabled: root.motionEnabled
        width: about.availableWidth
        spacing: Kirigami.Units.largeSpacing
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 42
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.largeSpacing
            Photo { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 14; cornerRadius: SpaceStyle.radius; cornerColor: SpaceStyle.voidColor; path: "/photos/flight-13"; useJxl: backend.supports_jxl; motionEnabled: root.motionEnabled; description: "Starship at sunset, photographed by Max Evans" }
            SectionLabel { text: "03 / THE PROGRAM"; color: SpaceStyle.dim }
            Kirigami.Heading { text: "A future beyond Earth."; level: 1; font.family: SpaceStyle.serif; font.pointSize: 31.5; color: SpaceStyle.text; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "SpaceX’s reusable transportation system in development, designed to carry people and cargo to Earth orbit, the Moon, Mars, and beyond. This independent archive follows each integrated flight test and the lessons learned along the way."; wrapMode: Text.WordWrap }
            Controls.Button { font.family: SpaceStyle.sans; text: "Starship at SpaceX"; icon.name: "internet-services"; onClicked: Qt.openUrlExternally("https://www.spacex.com/vehicles/starship") }
            Kirigami.Separator { Layout.fillWidth: true }
            SectionLabel { text: "CREDITS / SOURCES / PHOTOGRAPHY" }
            Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "Flight archive: mission reports and researched flight histories, reviewed 30 September 2026.\nIndependent analysis and geolocation: The Space Engineer (@mcrs987); published precision is preserved.\nPhotography: Max Evans / NSF and SpaceX.\nLaunch schedule: NextSpaceflight.\n\nUnaffiliated with SpaceX or NASASpaceflight."; wrapMode: Text.WordWrap; color: SpaceStyle.muted }
            Controls.Button { font.family: SpaceStyle.sans; text: "Max Evans’s photo galleries"; icon.name: "camera-photo"; onClicked: Qt.openUrlExternally("https://maxevans.smugmug.com/Rockets") }
        }
    }
}

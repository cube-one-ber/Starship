pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtCore as Core
import org.kde.kirigami as Kirigami
import org.starship.journal

Kirigami.ApplicationWindow {
    id: window
    title: "Starship"
    width: Kirigami.Units.gridUnit * 76
    height: Kirigami.Units.gridUnit * 50
    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 30
    visible: true
    font.family: SpaceStyle.sans
    color: SpaceStyle.voidColor
    Kirigami.Theme.inherit: false
    Kirigami.Theme.backgroundColor: SpaceStyle.voidColor
    Kirigami.Theme.alternateBackgroundColor: SpaceStyle.surface
    Kirigami.Theme.textColor: SpaceStyle.text
    Kirigami.Theme.disabledTextColor: SpaceStyle.muted
    Kirigami.Theme.highlightColor: SpaceStyle.accent
    Kirigami.Theme.highlightedTextColor: SpaceStyle.voidColor
    Kirigami.Theme.linkColor: SpaceStyle.accent
    Kirigami.Theme.focusColor: SpaceStyle.accent
    Kirigami.Theme.hoverColor: SpaceStyle.accent
    Kirigami.Theme.positiveTextColor: SpaceStyle.positive
    Kirigami.Theme.neutralTextColor: SpaceStyle.accent
    palette.window: SpaceStyle.voidColor
    palette.windowText: SpaceStyle.text
    palette.base: SpaceStyle.surface
    palette.text: SpaceStyle.text
    palette.button: SpaceStyle.raised
    palette.buttonText: SpaceStyle.text
    palette.highlight: SpaceStyle.accent
    palette.highlightedText: SpaceStyle.voidColor
    readonly property bool smokeTest: Qt.application.arguments.indexOf("--smoke-test") >= 0
    readonly property bool narrowTest: Qt.application.arguments.indexOf("--narrow-test") >= 0
    readonly property var flights: JSON.parse(flightBackend.flights_json)
    readonly property var schedule: JSON.parse(flightBackend.schedule_json)
    readonly property var scheduleState: JSON.parse(flightBackend.schedule_state_json)
    readonly property var countdown: JSON.parse(flightBackend.countdown_json)
    property var flightArchive: []
    readonly property int latestFlightId: flightArchive.length ? flightArchive[0].id : 14
    property string section: "archive"
    property alias reduceMotion: appearance.reduceMotion
    property bool forceReducedMotion: Qt.application.arguments.indexOf("--reduce-motion") >= 0
    readonly property bool motionEnabled: !reduceMotion && !forceReducedMotion && Kirigami.Units.longDuration > 0
    Core.Settings { id: appearance; category: "Appearance"; property bool reduceMotion: false }
    pageStack.defaultColumnWidth: width
    pageStack.columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn

    FlightBackend { id: flightBackend }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: flightBackend.tick() }
    Timer { interval: 600000; running: !window.smokeTest; repeat: true; onTriggered: flightBackend.refresh() }
    Component.onCompleted: {
        flightArchive = flights
        if (narrowTest) { width = 420; height = 880 }
        flightBackend.tick()
        if (!smokeTest) flightBackend.refresh()
    }
    function navigate(component, name) {
        if (name === "archive" && section === "archive") {
            pageStack.pop(pageStack.get(0))
            pageStack.currentIndex = 0
        } else {
            section = name
            pageStack.clear()
            pageStack.push(component)
        }
        if (globalDrawer.modal) globalDrawer.close()
    }
    function showArchive() { navigate(archivePage, "archive") }
    function openFlight(flight) { pageStack.push(missionPage, { flight: flight }) }

    globalDrawer: Kirigami.GlobalDrawer {
        title: ""
        titleIcon: ""
        background: Rectangle {
            gradient: Gradient { GradientStop { position: 0; color: "#111b26" } GradientStop { position: 0.55; color: SpaceStyle.voidColor } }
            Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: SpaceStyle.line }
        }
        header: Controls.Control {
            Layout.minimumWidth: 216
            padding: 24
            topPadding: 36
            bottomPadding: 32
            contentItem: ColumnLayout {
                spacing: 12
                RowLayout {
                    spacing: 10
                    Kirigami.Icon { source: "qrc:/icon.svg"; Layout.preferredWidth: 32; Layout.preferredHeight: 38 }
                    Controls.Label { font.family: SpaceStyle.sans; text: "STARSHIP"; font.pointSize: 13.5; font.weight: Font.Medium; font.letterSpacing: 2.5; color: SpaceStyle.text }
                }
                SectionLabel { text: "THE FLIGHT ARCHIVE"; color: SpaceStyle.dim; font.pointSize: 9; font.letterSpacing: 0.8 }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
            }
        }
        topContent: [ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.alignment: Qt.AlignTop
            spacing: 7
            SectionLabel { text: "EXPLORE THE JOURNEY"; color: SpaceStyle.dim; leftPadding: 12; bottomPadding: 12; font.pointSize: 9; font.letterSpacing: 1 }
            NavigationItem { objectName: "archiveNavigation"; Layout.fillWidth: true; text: "Flight archive"; icon.name: "view-grid"; number: "01"; selected: window.section === "archive"; motionEnabled: window.motionEnabled; onClicked: window.navigate(archivePage, "archive") }
            NavigationItem { objectName: "launchNavigation"; Layout.fillWidth: true; text: "Next launch"; icon.name: "chronometer"; number: "02"; selected: window.section === "launch"; motionEnabled: window.motionEnabled; onClicked: window.navigate(launchPage, "launch") }
            NavigationItem { objectName: "aboutNavigation"; Layout.fillWidth: true; text: "About Starship"; icon.name: "help-about"; number: "03"; selected: window.section === "about"; motionEnabled: window.motionEnabled; onClicked: window.navigate(aboutPage, "about") }
        }]
        modal: window.width < Kirigami.Units.gridUnit * 45
        onModalChanged: if (modal) close()
        collapsed: false
        isMenu: false
        footer: Controls.Control {
            padding: 24
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.largeSpacing
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    clip: true
                    OrbitalArtwork { anchors.fill: parent; ink: SpaceStyle.accent; opacity: 0.55 }
                }
                Controls.Label { Layout.fillWidth: true; text: "From Earth, onwards."; color: SpaceStyle.softAccent; font.family: SpaceStyle.serif; font.italic: true; font.pointSize: 14; wrapMode: Text.WordWrap }
                Controls.Label { Layout.fillWidth: true; text: "An independent record\nof extraordinary ambition."; color: SpaceStyle.dim; font.family: SpaceStyle.sans; font.pointSize: 9; lineHeight: 1.35; wrapMode: Text.WordWrap }
                Item { implicitHeight: 4 }
                Controls.CheckBox { font.family: SpaceStyle.sans; text: "Reduce motion"; checked: window.reduceMotion; onToggled: window.reduceMotion = checked }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
                SectionLabel { text: "EARTH → ORBIT → BEYOND"; color: SpaceStyle.dim; font.pointSize: 9; font.letterSpacing: 0.5 }
            }
        }
    }
    pageStack.initialPage: archivePage

    Component { id: archivePage; ArchivePage { root: window; backend: flightBackend } }

    Component { id: missionPage; MissionPage { root: window; backend: flightBackend } }

    Component { id: launchPage; LaunchPage { root: window; backend: flightBackend } }

    Component { id: aboutPage; AboutPage { root: window; backend: flightBackend } }

    Loader {
        active: window.smokeTest
        sourceComponent: Component { SmokeRunner { root: window; backend: flightBackend } }
    }
}

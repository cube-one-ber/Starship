pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtCore as Core
import org.kde.kirigami as Kirigami
import org.starship.journal

Kirigami.ApplicationWindow {
    id: root
    title: "Starship Journal"
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
    readonly property var flights: JSON.parse(backend.flights_json)
    readonly property var schedule: JSON.parse(backend.schedule_json)
    readonly property var countdown: JSON.parse(backend.countdown_json)
    property var flightArchive: []
    readonly property int latestFlightId: flightArchive.length ? flightArchive[0].id : 14
    property string section: "archive"
    property alias reduceMotion: appearance.reduceMotion
    property bool forceReducedMotion: Qt.application.arguments.indexOf("--reduce-motion") >= 0
    readonly property bool motionEnabled: !reduceMotion && !forceReducedMotion && Kirigami.Units.longDuration > 0
    Core.Settings { id: appearance; category: "Appearance"; property bool reduceMotion: false }
    pageStack.defaultColumnWidth: width
    pageStack.columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn

    FlightBackend { id: backend }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: backend.tick() }
    Timer { interval: 600000; running: !root.smokeTest; repeat: true; onTriggered: backend.refresh() }
    Component.onCompleted: {
        flightArchive = flights
        if (narrowTest) { width = 420; height = 880 }
        backend.tick()
        if (!smokeTest) backend.refresh()
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
                SectionLabel { text: "THE FLIGHT JOURNAL"; color: SpaceStyle.dim; font.pointSize: 9; font.letterSpacing: 0.8 }
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
            NavigationItem { objectName: "archiveNavigation"; Layout.fillWidth: true; text: "Flight archive"; icon.name: "view-grid"; number: "01"; selected: root.section === "archive"; motionEnabled: root.motionEnabled; onClicked: root.navigate(archivePage, "archive") }
            NavigationItem { objectName: "launchNavigation"; Layout.fillWidth: true; text: "Next launch"; icon.name: "chronometer"; number: "02"; selected: root.section === "launch"; motionEnabled: root.motionEnabled; onClicked: root.navigate(launchPage, "launch") }
            NavigationItem { objectName: "aboutNavigation"; Layout.fillWidth: true; text: "About Starship"; icon.name: "help-about"; number: "03"; selected: root.section === "about"; motionEnabled: root.motionEnabled; onClicked: root.navigate(aboutPage, "about") }
        }]
        modal: root.width < Kirigami.Units.gridUnit * 45
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
                Controls.CheckBox { font.family: SpaceStyle.sans; text: "Reduce motion"; checked: root.reduceMotion; onToggled: root.reduceMotion = checked }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
                SectionLabel { text: "EARTH → ORBIT → BEYOND"; color: SpaceStyle.dim; font.pointSize: 9; font.letterSpacing: 0.5 }
            }
        }
    }
    pageStack.initialPage: archivePage

    Component {
        id: archivePage
        Kirigami.ScrollablePage {
            id: archive
            property alias searchControl: searchField
            property alias yearControl: yearFilter
            property var presentedFlights: []
            Component.onCompleted: presentedFlights = root.flights
            property alias resultsMotion: results
            property alias gridControl: flightGrid
            readonly property bool wideHeader: availableWidth > Kirigami.Units.gridUnit * 48
            readonly property bool filtersActive: searchField.text.length > 0 || yearFilter.currentIndex > 0
            function clearFilters() { searchField.text = ""; yearFilter.currentIndex = 0 }
            title: "Flight archive"
            padding: root.narrowTest || root.width < 810 ? 20 : 32
            Connections {
                target: root
                function onFlightsChanged() { results.swap(function() { archive.presentedFlights = root.flights }) }
            }
            AnimatedColumn {
                motionEnabled: root.motionEnabled
                width: archive.availableWidth
                spacing: 24
                GridLayout {
                    Layout.fillWidth: true
                    columns: archive.wideHeader ? 2 : 1
                    columnSpacing: Kirigami.Units.largeSpacing * 2
                    rowSpacing: Kirigami.Units.largeSpacing * 2
                    JournalHero {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: archive.availableWidth * 0.65
                        useJxl: backend.supports_jxl
                        motionEnabled: root.motionEnabled
                        compact: archive.availableWidth < 540
                        flightCount: root.flightArchive.length
                        onExploreRequested: root.openFlight(JSON.parse(backend.mission(root.latestFlightId)))
                    }
                    CountdownPanel {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: archive.availableWidth * 0.35
                        schedule: root.schedule
                        motionEnabled: root.motionEnabled
                        compact: !archive.wideHeader
                        collapsible: !archive.wideHeader
                        countdown: root.countdown
                        busy: backend.busy
                        errorMessage: backend.error_message
                        onRefreshRequested: backend.refresh()
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    RowLayout {
                        Layout.fillWidth: true
                        SectionLabel { Layout.fillWidth: true; text: "01 / THE RECORD"; color: SpaceStyle.dim }
                        SectionLabel {
                            text: root.flightArchive.length ? root.flightArchive[root.flightArchive.length - 1].date.slice(0, 4) + " — " + root.flightArchive[0].date.slice(0, 4) : ""
                            color: SpaceStyle.dim
                            font.letterSpacing: 1
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.Heading { text: archive.availableWidth < 500 ? "Flight archive." : "The flight archive."; level: 1; font.family: SpaceStyle.serif; font.pointSize: archive.availableWidth < 500 ? 24 : 28.5; font.letterSpacing: -0.5; color: SpaceStyle.text; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        Controls.Control {
                            padding: 9
                            leftPadding: 12
                            rightPadding: 12
                            background: Rectangle { radius: 15; color: "#20eac38e"; border.color: "#45eac38e" }
                            contentItem: Controls.Label { text: root.flightArchive.length + " FLIGHTS"; font.family: SpaceStyle.mono; font.pointSize: 9; color: SpaceStyle.accent; font.letterSpacing: 0.8 }
                        }
                    }
                    Controls.Label { font.family: SpaceStyle.sans; text: "From the first liftoff to orbit. Every test moves the horizon."; color: SpaceStyle.muted; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
                Controls.Control {
                    Layout.fillWidth: true
                    padding: 14
                    background: Rectangle { radius: SpaceStyle.radius; color: SpaceStyle.surface; border.color: SpaceStyle.line }
                    contentItem: ColumnLayout {
                        spacing: 10
                        GridLayout {
                            Layout.fillWidth: true
                            columns: archive.availableWidth < 500 ? 1 : 2
                            columnSpacing: 12
                            rowSpacing: 10
                            Kirigami.SearchField {
                                font.family: SpaceStyle.sans
                                id: searchField
                                Layout.fillWidth: true
                                Layout.minimumHeight: 40
                                placeholderText: archive.availableWidth < 500 ? "Search flights and milestones…" : "Search titles, milestones, or flight numbers…"
                                Accessible.name: "Search the flight archive"
                                onTextChanged: backend.filter(yearFilter.currentText, text)
                            }
                            Controls.ComboBox {
                                font.family: SpaceStyle.sans
                                id: yearFilter
                                Layout.fillWidth: archive.availableWidth < 500
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                                Layout.minimumHeight: 40
                                model: ["All years", "2026", "2025", "2024", "2023"]
                                Accessible.name: "Filter by year"
                                onCurrentTextChanged: backend.filter(currentText, searchField.text)
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 30
                            Controls.Label {
                                Layout.fillWidth: true
                                text: "Showing " + root.flights.length + " of " + root.flightArchive.length + " flights"
                                font.family: SpaceStyle.sans
                                font.pointSize: 9
                                color: SpaceStyle.muted
                                elide: Text.ElideRight
                                Accessible.role: Accessible.StaticText
                            }
                            Controls.ToolButton {
                                objectName: "clearFiltersButton"
                                visible: archive.filtersActive
                                text: "Clear filters"
                                icon.name: "edit-clear"
                                font.family: SpaceStyle.sans
                                font.pointSize: 9
                                onClicked: archive.clearFilters()
                            }
                            SectionLabel { visible: !archive.filtersActive; text: "LATEST FIRST"; font.pointSize: 9; font.letterSpacing: 0.5; color: SpaceStyle.dim }
                        }
                    }
                }
                AnimatedColumn {
                    id: results
                    Layout.fillWidth: true
                    // Let the animated wrapper grow before CardsLayout computes its columns.
                    Layout.maximumWidth: Infinity
                    motionEnabled: root.motionEnabled
                    spacing: Kirigami.Units.largeSpacing * 2
                    Kirigami.CardsLayout {
                        id: flightGrid
                        Layout.fillWidth: true
                        minimumColumnWidth: Kirigami.Units.gridUnit * 18
                        maximumColumnWidth: Kirigami.Units.gridUnit * 26
                        maximumColumns: 3
                        uniformCellWidths: true
                        columnSpacing: Kirigami.Units.largeSpacing * 2
                        rowSpacing: Kirigami.Units.largeSpacing * 2
                        Repeater {
                            model: archive.presentedFlights
                            delegate: FlightCard {
                                required property var modelData
                                required property int index
                                entranceIndex: index % Math.max(1, flightGrid.columns)
                                motionEnabled: root.motionEnabled
                                inViewport: {
                                    // Include layout positions as binding dependencies as well as scrolling.
                                    const layoutY = y + flightGrid.y + results.y
                                    const top = mapToItem(archive.flickable.contentItem, 0, 0).y
                                    const scroll = archive.flickable.contentY
                                    return top + height >= scroll && top <= scroll + archive.flickable.height + Kirigami.Units.gridUnit
                                }
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                flight: modelData
                                latest: modelData.id === root.latestFlightId
                                useJxl: backend.supports_jxl
                                onActivated: flight => root.openFlight(flight)
                            }
                        }
                    }
                    Kirigami.PlaceholderMessage {
                        objectName: "emptyResults"
                        Layout.fillWidth: true
                        visible: archive.presentedFlights.length === 0
                        text: "No flights found"
                        explanation: "Try another year or search term."
                        icon.name: "edit-find"
                        helpfulAction: Kirigami.Action { text: "Clear filters"; onTriggered: archive.clearFilters() }
                    }
                }
                Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "Latest flights first. Photography: Max Evans / NSF and SpaceX."; color: SpaceStyle.muted; wrapMode: Text.WordWrap }
            }
        }
    }
    Component {
        id: missionPage
        Kirigami.ScrollablePage {
            id: mission
            required property var flight
            property alias contentMotion: missionContent
            function jumpTo(section) {
                const target = section === "overview" ? missionOverview
                    : section === "log" ? missionReport.logTarget
                    : section === "analysis" ? missionReport.analysisTarget
                    : section === "timeline" ? missionReport.timelineTarget : missionReport.recoveryTarget
                const top = target.mapToItem(mission.flickable.contentItem, 0, 0).y - 16
                mission.flickable.contentY = Math.max(0, Math.min(top, mission.flickable.contentHeight - mission.flickable.height))
            }
            function changeFlight(id) {
                const next = JSON.parse(backend.mission(id))
                if (!next) return
                const direction = id > flight.id ? 1 : -1
                missionContent.swap(function() { mission.flight = next; mission.flickable.contentY = 0 }, direction)
            }
            title: "Flight " + flight.id
            padding: root.narrowTest || root.width < 810 ? 20 : 32
            actions: [Kirigami.Action { text: "Official report"; icon.name: "internet-services"; onTriggered: Qt.openUrlExternally(mission.flight.source) }]
            header: Controls.Control {
                leftPadding: mission.padding
                rightPadding: mission.padding
                topPadding: 6
                bottomPadding: 6
                background: Rectangle { color: SpaceStyle.voidColor; Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: SpaceStyle.line } }
                contentItem: ColumnLayout {
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        Controls.Button { objectName: "returnToArchive"; text: "Flight archive"; icon.name: "view-grid"; font.family: SpaceStyle.sans; onClicked: root.navigate(archivePage, "archive") }
                        Item { Layout.fillWidth: true }
                        Controls.ToolButton { text: "Flight " + (mission.flight.id - 1); icon.name: "go-previous"; font.family: SpaceStyle.sans; enabled: mission.flight.id > 1; Accessible.name: "Previous flight, Flight " + (mission.flight.id - 1); onClicked: mission.changeFlight(mission.flight.id - 1) }
                        Controls.ToolButton { text: "Flight " + (mission.flight.id + 1); icon.name: "go-next"; font.family: SpaceStyle.sans; visible: mission.flight.id < root.latestFlightId; Accessible.name: "Next flight, Flight " + (mission.flight.id + 1); onClicked: mission.changeFlight(mission.flight.id + 1) }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: [{ label: "Overview", section: "overview" }, { label: "Flight log", section: "log" }, { label: "Analysis", section: "analysis" }, { label: "Timeline", section: "timeline" }, { label: "Recovery", section: "recovery" }]
                            delegate: Controls.ToolButton {
                                required property var modelData
                                objectName: "missionJump_" + modelData.section
                                visible: modelData.section !== "recovery" || mission.flight.landings.length > 0
                                text: modelData.label
                                font.family: SpaceStyle.sans
                                font.pointSize: 10
                                onClicked: mission.jumpTo(modelData.section)
                            }
                        }
                    }
                }
            }
            AnimatedColumn {
                id: missionContent
                motionEnabled: root.motionEnabled
                width: mission.availableWidth
                spacing: 28
                Photo {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(mission.width / 2, 300)
                    cornerRadius: SpaceStyle.radius
                    cornerColor: SpaceStyle.voidColor
                    path: mission.flight.photo.path
                    useJxl: backend.supports_jxl
                    motionEnabled: root.motionEnabled
                    description: mission.flight.photo.alt
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1; color: "#df090e16" } }
                    }
                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: mission.width < 600 ? 20 : 32
                        spacing: 7
                        SectionLabel { Layout.fillWidth: true; text: "MISSION DEBRIEF / STARBASE" }
                        Controls.Label { font.family: SpaceStyle.sans; text: "FLIGHT " + String(mission.flight.id).padStart(3, "0"); color: SpaceStyle.text; font.pointSize: (mission.width < 600 ? 30 : 46) * 0.75; font.weight: Font.Light; font.letterSpacing: 3 }
                        Controls.Label { Layout.fillWidth: true; text: new Date(mission.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMMM yyyy") + "  ·  " + mission.flight.outcome; color: "#dbe2eb"; font.family: SpaceStyle.sans; font.pointSize: 10.5; wrapMode: Text.WordWrap }
                    }
                }
                ColumnLayout {
                    id: missionOverview
                    Layout.fillWidth: true
                    Layout.maximumWidth: 860
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.largeSpacing * 2
                    Kirigami.Heading { text: mission.flight.title; level: 1; font.family: SpaceStyle.serif; font.pointSize: (mission.width < 600 ? 34 : 44) * 0.75; font.letterSpacing: -0.7; color: SpaceStyle.text; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Controls.Label { font.family: SpaceStyle.sans; text: mission.flight.summary; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: SpaceStyle.muted; font.pointSize: 12; lineHeight: 1.4 }
                    Controls.Control {
                        Layout.fillWidth: true
                        padding: 22
                        background: Rectangle { radius: SpaceStyle.radius; color: SpaceStyle.surface; border.color: SpaceStyle.line }
                        contentItem: GridLayout {
                            columns: mission.width < 650 ? 2 : 3
                            columnSpacing: 24
                            rowSpacing: 24
                            MissionStat { Layout.fillWidth: true; label: "LIFTOFF / UTC"; value: new Date(mission.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMM yyyy") + "\n" + mission.flight.launch_time }
                            MissionStat { Layout.fillWidth: true; label: "LAUNCH SITE"; value: mission.flight.launch_site }
                            MissionStat { Layout.fillWidth: true; label: "TRAJECTORY"; value: mission.flight.trajectory }
                            MissionStat { Layout.fillWidth: true; label: "SUPER HEAVY"; value: mission.flight.booster_id + "\n" + mission.flight.booster }
                            MissionStat { Layout.fillWidth: true; label: "STARSHIP / " + mission.flight.generation; value: mission.flight.ship_id + "\n" + mission.flight.ship }
                            MissionStat { Layout.fillWidth: true; label: "PAYLOAD / EXPERIMENT"; value: mission.flight.payload; valueColor: SpaceStyle.cyan }
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true }
                    MissionReport { id: missionReport; Layout.fillWidth: true; flight: mission.flight }
                    Controls.Label { font.family: SpaceStyle.sans; text: mission.flight.photo.credit; color: SpaceStyle.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Kirigami.ActionToolBar {
                        Layout.fillWidth: true
                        actions: [
                            Kirigami.Action { text: "Official report & replay"; icon.name: "internet-services"; onTriggered: Qt.openUrlExternally(mission.flight.source) },
                            Kirigami.Action { text: "Photo credit"; icon.name: "camera-photo"; onTriggered: Qt.openUrlExternally(mission.flight.photo.url) }
                        ]
                    }
                    Kirigami.Separator { Layout.fillWidth: true }
                    RowLayout {
                        Layout.fillWidth: true
                        Controls.Button { font.family: SpaceStyle.sans; text: "Previous · Flight " + (mission.flight.id - 1); icon.name: "go-previous"; enabled: mission.flight.id > 1; onClicked: mission.changeFlight(mission.flight.id - 1) }
                        Item { Layout.fillWidth: true }
                        Controls.Button { font.family: SpaceStyle.sans; text: "Next · Flight " + (mission.flight.id + 1); icon.name: "go-next"; enabled: mission.flight.id < root.latestFlightId; onClicked: mission.changeFlight(mission.flight.id + 1) }
                    }
                }
            }
        }
    }
    Component {
        id: launchPage
        Kirigami.ScrollablePage {
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
                    CountdownPanel { Layout.fillWidth: true; motionEnabled: root.motionEnabled; schedule: root.schedule; countdown: root.countdown; busy: backend.busy; errorMessage: backend.error_message; onRefreshRequested: backend.refresh() }
                    Photo { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 14; cornerRadius: SpaceStyle.radius; cornerColor: SpaceStyle.voidColor; path: "/photos/hero"; useJxl: backend.supports_jxl; motionEnabled: root.motionEnabled; description: "Starship launching from Starbase" }
                    Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "Launch timing may change as vehicles are tested and prepared. Only precise launch times are used for the countdown; provisional months and quarters are not treated as confirmed dates."; wrapMode: Text.WordWrap }
                }
            }
        }
    }
    Component {
        id: aboutPage
        Kirigami.ScrollablePage {
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
                    Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "SpaceX’s reusable transportation system in development, designed to carry people and cargo to Earth orbit, the Moon, Mars, and beyond. This independent journal follows each integrated flight test and the lessons learned along the way."; wrapMode: Text.WordWrap }
                    Controls.Button { font.family: SpaceStyle.sans; text: "Starship at SpaceX"; icon.name: "internet-services"; onClicked: Qt.openUrlExternally("https://www.spacex.com/vehicles/starship") }
                    Kirigami.Separator { Layout.fillWidth: true }
                    SectionLabel { text: "SOURCES / PEOPLE / PHOTOGRAPHY" }
                    Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "Flight archive: mission reports and researched flight histories, reviewed 30 September 2026.\nCoordinate analysis: @mcrs987; published precision is preserved.\nPhotography: Max Evans / NSF and SpaceX.\nLaunch schedule: NextSpaceflight.\n\nUnaffiliated with SpaceX or NASASpaceflight."; wrapMode: Text.WordWrap; color: SpaceStyle.muted }
                    Controls.Button { font.family: SpaceStyle.sans; text: "Max Evans’s photo galleries"; icon.name: "camera-photo"; onClicked: Qt.openUrlExternally("https://maxevans.smugmug.com/Rockets") }
                }
            }
        }
    }
    function descendants(item, name) {
        let result = []
        if (item.objectName === name) result.push(item)
        if (item.children) for (let child of item.children) result = result.concat(descendants(child, name))
        return result
    }
    Timer {
        id: previewFrames
        property int frame: 0
        interval: 80
        repeat: true
        running: root.smokeTest && Qt.application.arguments.indexOf("--motion-preview") >= 0 && frame < 140
        onTriggered: {
            backend.capture(backend.test_output_path("starship-motion-" + String(frame).padStart(4, "0") + ".png"))
            frame += 1
        }
    }
    // The smoke runner inspects page-specific properties on a dynamic page stack.
    // qmllint disable missing-property
    Timer {
        id: smokeRunner
        property int phase: 0
        property var archiveSnapshot: null
        interval: 1600
        repeat: true
        running: root.smokeTest
        onTriggered: {
            try {
                // The page stack is dynamic; each phase exercises its actual controls.
                const page = root.pageStack.currentItem
                if (phase === 0) {
                    if (!backend.appearance_ready()) throw new Error("Breeze style or KDE icons are missing")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-narrow.png" : "starship-kirigami-desktop.png"))) throw new Error("Could not capture archive")
                    if (root.flights.length !== 14 || root.flightArchive.length !== 14 || page.presentedFlights.length !== 14) throw new Error("Archive must contain 14 flights")
                    if (!root.narrowTest && page.gridControl.columns !== 3) throw new Error("Desktop archive did not retain three columns")
                    const firstCard = root.descendants(page, "flightCard")[0]
                    if (firstCard.mapToItem(page.flickable.contentItem, 0, 0).y >= page.flickable.height) throw new Error("Initial viewport must show the first flight card")
                    const launch = root.descendants(page, "launchPanel")[0]
                    launch.schedule = Object.assign({}, root.schedule, { launchAt: "2026-10-01T23:50:00Z" })
                    launch.countdown = { days: "01", hours: "02", minutes: "03", seconds: "04" }
                    if (launch.windowText !== "2026-10-01 · 23:50 UTC") throw new Error("Precise launch window must use a consistent UTC date and time")
                    launch.schedule = Qt.binding(function() { return root.schedule })
                    launch.countdown = Qt.binding(function() { return root.countdown })
                    if (root.narrowTest) {
                        if (!launch.collapsible || launch.detailsVisible) throw new Error("Narrow launch summary must start collapsed")
                        const toggle = root.descendants(launch, "launchDetailsToggle")[0]
                        toggle.clicked()
                        if (!launch.detailsVisible) throw new Error("Launch details did not expand")
                        toggle.clicked()
                        if (launch.detailsVisible) throw new Error("Launch details did not collapse")
                    }
                    page.yearControl.currentIndex = 4
                    if (root.flights.length !== 2) throw new Error("Year control did not filter the archive")
                    page.yearControl.currentIndex = 0
                    page.searchControl.text = "first booster catch"
                    if (root.flights.length !== 1 || root.flights[0].id !== 5) throw new Error("Search control did not filter missions")
                    if (root.narrowTest) page.flickable.contentY = Math.max(0, page.searchControl.mapToItem(page.flickable.contentItem, 0, 0).y - 24)
                } else if (phase === 1) {
                    if (page.presentedFlights.length !== 1 || page.presentedFlights[0].id !== 5 || page.resultsMotion.transitioning) throw new Error("Rapid filters did not settle on the latest results")
                    if (root.flightArchive.length !== 14 || root.latestFlightId !== 14) throw new Error("Filtering changed the archive overview or latest mission")
                    const clear = root.descendants(page, "clearFiltersButton")[0]
                    if (!clear || !clear.visible) throw new Error("Active filters must expose a clear action")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-filtered-narrow.png" : "starship-kirigami-filtered.png"))) throw new Error("Could not capture filtered archive")
                    page.searchControl.text = "no matching flight"
                } else if (phase === 2) {
                    if (page.presentedFlights.length !== 0) throw new Error("Empty filter results were not displayed")
                    const message = root.descendants(page, "emptyResults")[0]
                    if (!message || !message.visible) throw new Error("Empty results message is missing")
                    page.yearControl.currentIndex = 4
                    const clear = root.descendants(page, "clearFiltersButton")[0]
                    clear.clicked()
                    if (page.searchControl.text !== "" || page.yearControl.currentIndex !== 0 || page.filtersActive) throw new Error("Clear filters did not reset both controls")
                } else if (phase === 3) {
                    if (page.presentedFlights.length !== 14) throw new Error("Clearing filters did not restore the archive")
                    const card = root.descendants(page, "flightCard")[0]
                    card.forceActiveFocus()
                } else if (phase === 4) {
                    const card = root.descendants(page, "flightCard")[0]
                    const photo = root.descendants(card, "journalPhoto")[0]
                    const expectedScale = root.motionEnabled ? 1.045 : 1
                    if (!card.activeFocus || Math.abs(photo.imageScale - expectedScale) > 0.001) throw new Error("Keyboard focus did not produce the expected photo feedback")
                    card.activated(card.flight)
                } else if (phase === 5) {
                    if (page.flight.id !== 14) throw new Error("Card did not open the mission page")
                    if (page.flight.landings.length !== 2 || page.flight.landings[1].coordinates !== "25°29′57.46″N · 155°25′39.13″W") throw new Error("Flight 14 geolocations are missing")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-mission-narrow.png" : "starship-kirigami-mission.png"))) throw new Error("Could not capture mission")
                    const timelineJump = root.descendants(page, "missionJump_timeline")[0]
                    if (!timelineJump) throw new Error("Mission section navigation is missing")
                    timelineJump.clicked()
                    if (page.flickable.contentY <= 0) throw new Error("Timeline navigation did not scroll the report")
                    const locations = root.descendants(page, "landingEstimate")
                    if (locations.length !== 2) throw new Error("Both Flight 14 location panels must render")
                    root.descendants(page, "missionJump_recovery")[0].clicked()
                    const recoveryTop = locations[0].mapToItem(page.flickable.contentItem, 0, 0).y
                    if (recoveryTop < page.flickable.contentY || recoveryTop >= page.flickable.contentY + page.flickable.height) throw new Error("Recovery navigation did not reach the landing panels")
                    page.flickable.contentY = Math.max(0, locations[1].mapToItem(page.flickable.contentItem, 0, 0).y - 90)
                } else if (phase === 6) {
                    const coordinates = root.descendants(page, "landingCoordinates")[1]
                    if (!coordinates || coordinates.text !== "25°29′57.46″N · 155°25′39.13″W" || coordinates.width > page.availableWidth) throw new Error("Ship 41 location did not render correctly")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-flight14-coordinates-narrow.png" : "starship-kirigami-flight14-coordinates.png"))) throw new Error("Could not capture Flight 14 coordinates")
                    page.changeFlight(13)
                    page.changeFlight(12)
                } else if (phase === 7) {
                    if (page.flight.id !== 12 || page.contentMotion.transitioning) throw new Error("Rapid mission changes did not settle on the latest flight")
                    const photo = root.descendants(page, "journalPhoto")[0]
                    if (!photo || photo.path !== page.flight.photo.path || photo.status !== Image.Ready) throw new Error("Mission photo did not follow the transition")
                    const coordinates = root.descendants(page, "landingCoordinates")[0]
                    const landing = root.descendants(page, "landingEstimate")[0]
                    const timeline = root.descendants(page, "missionTimeline")[0]
                    if (!landing || !landing.visible || !coordinates || coordinates.text !== "25°01′N · 94°10′W" || !timeline) throw new Error("Flight 12 research content is missing")
                    const analyses = root.descendants(page, "independentAnalysisEntry")
                    if (analyses.length !== 2 || analyses[0].width > page.availableWidth || analyses[0].height <= 0) throw new Error("Flight 12 analysis did not follow the mission change")
                    page.flickable.contentY = Math.max(0, landing.mapToItem(page.flickable.contentItem, 0, 0).y - 90)
                } else if (phase === 8) {
                    const coordinates = root.descendants(page, "landingCoordinates")[0]
                    if (coordinates.width > page.availableWidth || coordinates.height <= 0) throw new Error("Coordinate panel does not fit the mission page")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-coordinates-narrow.png" : "starship-kirigami-coordinates.png"))) throw new Error("Could not capture coordinate panel")
                    page.changeFlight(13)
                    const forced = root.forceReducedMotion
                    root.forceReducedMotion = true
                    if (page.flight.id !== 13 || page.contentMotion.opacity !== 1) throw new Error("Reducing motion did not finish the pending mission change")
                    root.forceReducedMotion = forced
                    const launchNav = root.descendants(root.globalDrawer.contentItem, "launchNavigation")[0]
                    if (!launchNav) throw new Error("Launch navigation is missing")
                    launchNav.clicked()
                } else if (phase === 9) {
                    if (page.title !== "Next launch") throw new Error("Launch navigation failed")
                    if (!root.descendants(root.globalDrawer.contentItem, "launchNavigation")[0].selected) throw new Error("Launch navigation did not become selected")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-launch-narrow.png" : "starship-kirigami-launch.png"))) throw new Error("Could not capture launch")
                    root.descendants(root.globalDrawer.contentItem, "aboutNavigation")[0].clicked()
                } else if (phase === 10) {
                    if (page.title !== "About Starship") throw new Error("About navigation failed")
                    if (!root.descendants(root.globalDrawer.contentItem, "aboutNavigation")[0].selected) throw new Error("About navigation did not become selected")
                    root.descendants(root.globalDrawer.contentItem, "archiveNavigation")[0].clicked()
                } else if (phase === 11) {
                    if (!root.descendants(root.globalDrawer.contentItem, "archiveNavigation")[0].selected) throw new Error("Archive navigation did not become selected")
                    const cards = root.descendants(page, "flightCard")
                    if (cards.length !== 14) throw new Error("Missing flight photos: " + cards.length)
                    for (let card of cards) {
                        if (card.status === Image.Error || !card.jxlLoaded) throw new Error("JPEG XL image did not decode for flight " + card.flight.id + " (status " + card.status + ", JXL " + card.jxlLoaded + ")")
                        // A recreated archive loads asynchronously; the runner's timeout bounds this wait.
                        if (card.status !== Image.Ready) return
                    }
                    page.flickable.contentY = root.narrowTest ? 720 : 500
                } else if (phase === 12) {
                    const cards = root.descendants(page, "flightCard")
                    for (let card of cards) if (card.inViewport && (!card.revealed || card.opacity < 0.99)) throw new Error("A visible card failed to appear after scrolling")
                    const saved = backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-cards-narrow.png" : "starship-kirigami-cards.png"))
                    if (!saved) throw new Error("Could not capture flight cards")
                    page.yearControl.currentIndex = 3
                    page.searchControl.text = "first booster catch"
                } else if (phase === 13) {
                    if (page.presentedFlights.length !== 1 || page.presentedFlights[0].id !== 5) throw new Error("Return-navigation filter setup failed")
                    page.flickable.contentY = Math.min(100, Math.max(0, page.flickable.contentHeight - page.flickable.height))
                    archiveSnapshot = { page: page, scroll: page.flickable.contentY, search: page.searchControl.text, year: page.yearControl.currentIndex }
                    root.openFlight(page.presentedFlights[0])
                } else if (phase === 14) {
                    if (page.flight.id !== 5) throw new Error("Filtered card did not open Flight 5")
                    if (!root.descendants(page, "missionJump_recovery")[0].visible || page.flight.landings[0].vehicle.indexOf("ring") < 0) throw new Error("Flight 5 discarded-ring location is missing")
                    const analyses = root.descendants(page, "independentAnalysisEntry")
                    if (analyses.length !== 2) throw new Error("Flight 5 analyses are missing")
                    root.descendants(page, "missionJump_analysis")[0].clicked()
                    const top = analyses[0].mapToItem(page.flickable.contentItem, 0, 0).y
                    if (top < page.flickable.contentY || top >= page.flickable.contentY + page.flickable.height) throw new Error("Analysis navigation did not reach the entries")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-analysis-narrow.png" : "starship-kirigami-analysis.png"))) throw new Error("Could not capture independent analysis")
                    root.descendants(page, "returnToArchive")[0].clicked()
                } else if (phase === 15) {
                    if (page !== archiveSnapshot.page || page.searchControl.text !== archiveSnapshot.search || page.yearControl.currentIndex !== archiveSnapshot.year || Math.abs(page.flickable.contentY - archiveSnapshot.scroll) > 2) throw new Error("Returning to the archive lost filters or scroll position")
                    console.log("SMOKE PASS: compact launch details, archive visibility, section navigation, preserved archive state, mission transitions, reduced motion, research content, and 14 JPEG XL cards")
                    backend.finish_test(true)
                    stop()
                }
                phase += 1
            } catch (error) {
                console.error("SMOKE FAIL: " + error)
                stop()
                backend.finish_test(false)
            }
        }
    }
    // qmllint enable missing-property
}

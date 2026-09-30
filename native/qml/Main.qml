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
        if (narrowTest) { width = 420; height = 880 }
        backend.tick()
        if (!smokeTest) backend.refresh()
    }
    function navigate(component, name) {
        section = name
        pageStack.clear()
        pageStack.push(component)
        if (globalDrawer.modal) globalDrawer.close()
    }
    function openFlight(flight) { pageStack.push(missionPage, { flight: flight }) }

    globalDrawer: Kirigami.GlobalDrawer {
        title: ""
        titleIcon: ""
        background: Rectangle { color: SpaceStyle.voidColor; border.color: SpaceStyle.line; border.width: 1 }
        header: Controls.Control {
            padding: 24
            topPadding: 36
            bottomPadding: 32
            contentItem: ColumnLayout {
                spacing: 12
                RowLayout {
                    Kirigami.Icon { source: "qrc:/icon.svg"; Layout.preferredWidth: 25; Layout.preferredHeight: 34 }
                    Controls.Label { font.family: SpaceStyle.sans; text: "STARSHIP"; font.pointSize: 15; font.weight: Font.Medium; font.letterSpacing: 3; color: SpaceStyle.text }
                }
                SectionLabel { text: "THE FLIGHT JOURNAL"; color: SpaceStyle.dim; font.pointSize: 6.75; font.letterSpacing: 1.4 }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
            }
        }
        topContent: [SectionLabel { text: "MISSION DIRECTORY"; color: SpaceStyle.dim; leftPadding: 24; bottomPadding: 16; font.pointSize: 6.75; font.letterSpacing: 1 }]
        modal: root.width < Kirigami.Units.gridUnit * 45
        collapsed: false
        isMenu: false
        actions: [
            Kirigami.Action { text: "Flight archive"; icon.name: "view-grid"; checkable: true; checked: root.section === "archive"; onTriggered: root.navigate(archivePage, "archive") },
            Kirigami.Action { text: "Next launch"; icon.name: "chronometer"; checkable: true; checked: root.section === "launch"; onTriggered: root.navigate(launchPage, "launch") },
            Kirigami.Action { text: "About Starship"; icon.name: "help-about"; checkable: true; checked: root.section === "about"; onTriggered: root.navigate(aboutPage, "about") }
        ]
        footer: Controls.Control {
            padding: 24
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.largeSpacing
                Controls.CheckBox { font.family: SpaceStyle.sans; text: "Reduce motion"; checked: root.reduceMotion; onToggled: root.reduceMotion = checked }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
                SectionLabel { text: "EARTH → ORBIT → BEYOND"; color: SpaceStyle.dim; font.pointSize: 6; font.letterSpacing: 0.7 }
                Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "An independent record of flight."; color: SpaceStyle.dim; wrapMode: Text.WordWrap; font.pointSize: 8.25}
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
            title: "Flight archive"
            padding: root.narrowTest || root.width < 810 ? 20 : 32
            actions: [Kirigami.Action { text: "Refresh schedule"; icon.name: "view-refresh"; enabled: !backend.busy; onTriggered: backend.refresh() }]
            Connections {
                target: root
                function onFlightsChanged() { results.swap(function() { archive.presentedFlights = root.flights }) }
            }
            AnimatedColumn {
                motionEnabled: root.motionEnabled
                width: archive.availableWidth
                spacing: 28
                GridLayout {
                    Layout.fillWidth: true
                    columns: archive.availableWidth > Kirigami.Units.gridUnit * 48 ? 2 : 1
                    columnSpacing: Kirigami.Units.largeSpacing * 2
                    rowSpacing: Kirigami.Units.largeSpacing * 2
                    JournalHero {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: archive.availableWidth * 0.62
                        useJxl: backend.supports_jxl
                        motionEnabled: root.motionEnabled
                        onExploreRequested: root.openFlight(JSON.parse(backend.mission(14)))
                    }
                    CountdownPanel {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: archive.availableWidth * 0.38
                        schedule: root.schedule
                        motionEnabled: root.motionEnabled
                        countdown: root.countdown
                        busy: backend.busy
                        errorMessage: backend.error_message
                        onRefreshRequested: backend.refresh()
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    SectionLabel { text: "01 / THE RECORD"; color: SpaceStyle.dim }
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.Heading { text: "Flight archive"; level: 1; font.family: SpaceStyle.serif; font.pointSize: 24; font.letterSpacing: -0.5; color: SpaceStyle.text; Layout.fillWidth: true }
                        Controls.Label { text: root.flights.length + (root.flights.length === 1 ? " flight" : " flights"); FadeBehavior on text { motionEnabled: root.motionEnabled } font.family: SpaceStyle.mono; font.pointSize: 8.25; color: SpaceStyle.accent }
                    }
                    Controls.Label { font.family: SpaceStyle.sans; text: "From the first liftoff to orbit. Every test moves the horizon."; color: SpaceStyle.muted; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.SearchField { font.family: SpaceStyle.sans;
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search flights…"
                        onTextChanged: backend.filter(yearFilter.currentText, text)
                    }
                    Controls.ComboBox { font.family: SpaceStyle.sans;
                        id: yearFilter
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                        model: ["All years", "2026", "2025", "2024", "2023"]
                        Accessible.name: "Filter by year"
                        onCurrentTextChanged: backend.filter(currentText, searchField.text)
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
                        helpfulAction: Kirigami.Action { text: "Clear filters"; onTriggered: { searchField.text = ""; yearFilter.currentIndex = 0 } }
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
            function changeFlight(id) {
                const next = JSON.parse(backend.mission(id))
                if (!next) return
                const direction = id > flight.id ? 1 : -1
                missionContent.swap(function() { mission.flight = next; mission.flickable.contentY = 0 }, direction)
            }
            title: "Flight " + flight.id
            padding: root.narrowTest || root.width < 810 ? 20 : 32
            actions: [Kirigami.Action { text: "Official report"; icon.name: "internet-services"; onTriggered: Qt.openUrlExternally(mission.flight.source) }]
            AnimatedColumn {
                id: missionContent
                motionEnabled: root.motionEnabled
                width: mission.availableWidth
                spacing: 28
                Photo {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(mission.width / 2, 390)
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
                        anchors.bottom: parent.bottom
                        anchors.margins: mission.width < 600 ? 20 : 32
                        spacing: 7
                        SectionLabel { text: "MISSION DEBRIEF / STARBASE" }
                        Controls.Label { font.family: SpaceStyle.sans; text: "FLIGHT " + String(mission.flight.id).padStart(3, "0"); color: SpaceStyle.text; font.pointSize: (mission.width < 600 ? 30 : 46) * 0.75; font.weight: Font.Light; font.letterSpacing: 3 }
                    }
                }
                ColumnLayout {
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
                            MissionStat { Layout.fillWidth: true; label: "LAUNCH DATE"; value: new Date(mission.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMM yyyy") }
                            MissionStat { Layout.fillWidth: true; label: "FLIGHT OUTCOME"; value: mission.flight.outcome; valueColor: mission.flight.outcome === "Vehicle lost" ? SpaceStyle.accent : SpaceStyle.positive }
                            MissionStat { Layout.fillWidth: true; label: "MILESTONE"; value: mission.flight.milestone }
                            MissionStat { Layout.fillWidth: true; label: "SUPER HEAVY"; value: mission.flight.booster }
                            MissionStat { Layout.fillWidth: true; label: "STARSHIP"; value: mission.flight.ship }
                            MissionStat { Layout.fillWidth: true; label: "MISSION SOURCE"; value: "SpaceX flight report"; valueColor: SpaceStyle.cyan }
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true }
                    SectionLabel { text: "FLIGHT LOG / WHAT HAPPENED" }
                    Repeater {
                        model: mission.flight.details
                        Kirigami.SelectableLabel { font.family: SpaceStyle.sans; required property string modelData; text: modelData; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: SpaceStyle.text; font.pointSize: 11.25 }
                    }
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
                        Controls.Button { font.family: SpaceStyle.sans; text: "Previous flight"; icon.name: "go-previous"; enabled: mission.flight.id > 1; onClicked: mission.changeFlight(mission.flight.id - 1) }
                        Item { Layout.fillWidth: true }
                        Controls.Button { font.family: SpaceStyle.sans; text: "Next flight"; icon.name: "go-next"; enabled: mission.flight.id < 14; onClicked: mission.changeFlight(mission.flight.id + 1) }
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
                    Photo { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 14; path: "/photos/hero"; useJxl: backend.supports_jxl; motionEnabled: root.motionEnabled; description: "Starship launching from Starbase" }
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
                    Photo { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 14; path: "/photos/flight-13"; useJxl: backend.supports_jxl; motionEnabled: root.motionEnabled; description: "Starship at sunset, photographed by Max Evans" }
                    SectionLabel { text: "03 / THE PROGRAM"; color: SpaceStyle.dim }
                    Kirigami.Heading { text: "A future beyond Earth."; level: 1; font.family: SpaceStyle.serif; font.pointSize: 31.5; color: SpaceStyle.text; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "SpaceX’s reusable transportation system in development, designed to carry people and cargo to Earth orbit, the Moon, Mars, and beyond. This independent journal follows each integrated flight test and the lessons learned along the way."; wrapMode: Text.WordWrap }
                    Controls.Button { font.family: SpaceStyle.sans; text: "Starship at SpaceX"; icon.name: "internet-services"; onClicked: Qt.openUrlExternally("https://www.spacex.com/vehicles/starship") }
                    Kirigami.Separator { Layout.fillWidth: true }
                    SectionLabel { text: "SOURCES / PEOPLE / PHOTOGRAPHY" }
                    Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: "Flight archive: SpaceX mission reports, reviewed September 29, 2026.\nPhotography: Max Evans / NSF and SpaceX.\nLaunch schedule: NextSpaceflight.\n\nUnaffiliated with SpaceX or NASASpaceflight."; wrapMode: Text.WordWrap; color: SpaceStyle.muted }
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
                    if (root.flights.length !== 14 || page.presentedFlights.length !== 14) throw new Error("Archive must contain 14 flights")
                    if (!root.narrowTest && page.gridControl.columns !== 3) throw new Error("Desktop archive did not retain three columns")
                    page.yearControl.currentIndex = 4
                    if (root.flights.length !== 2) throw new Error("Year control did not filter the archive")
                    page.yearControl.currentIndex = 0
                    page.searchControl.text = "first booster catch"
                    if (root.flights.length !== 1 || root.flights[0].id !== 5) throw new Error("Search control did not filter missions")
                } else if (phase === 1) {
                    if (page.presentedFlights.length !== 1 || page.presentedFlights[0].id !== 5 || page.resultsMotion.transitioning) throw new Error("Rapid filters did not settle on the latest results")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-filtered-narrow.png" : "starship-kirigami-filtered.png"))) throw new Error("Could not capture filtered archive")
                    page.searchControl.text = "no matching flight"
                } else if (phase === 2) {
                    if (page.presentedFlights.length !== 0) throw new Error("Empty filter results were not displayed")
                    const message = root.descendants(page, "emptyResults")[0]
                    if (!message || !message.visible) throw new Error("Empty results message is missing")
                    page.searchControl.text = ""
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
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-mission-narrow.png" : "starship-kirigami-mission.png"))) throw new Error("Could not capture mission")
                    page.changeFlight(13)
                    page.changeFlight(12)
                } else if (phase === 6) {
                    if (page.flight.id !== 12 || page.contentMotion.transitioning) throw new Error("Rapid mission changes did not settle on the latest flight")
                    const photo = root.descendants(page, "journalPhoto")[0]
                    if (!photo || photo.path !== page.flight.photo.path || photo.status !== Image.Ready) throw new Error("Mission photo did not follow the transition")
                    page.changeFlight(13)
                    const forced = root.forceReducedMotion
                    root.forceReducedMotion = true
                    if (page.flight.id !== 13 || page.contentMotion.opacity !== 1) throw new Error("Reducing motion did not finish the pending mission change")
                    root.forceReducedMotion = forced
                    root.navigate(launchPage, "launch")
                } else if (phase === 7) {
                    if (page.title !== "Next launch") throw new Error("Launch navigation failed")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-launch-narrow.png" : "starship-kirigami-launch.png"))) throw new Error("Could not capture launch")
                    root.navigate(aboutPage, "about")
                } else if (phase === 8) {
                    if (page.title !== "About Starship") throw new Error("About navigation failed")
                    root.navigate(archivePage, "archive")
                } else if (phase === 9) {
                    const cards = root.descendants(page, "flightCard")
                    if (cards.length !== 14) throw new Error("Missing flight photos: " + cards.length)
                    for (let card of cards) if (card.status !== Image.Ready || !card.jxlLoaded) throw new Error("JPEG XL image did not decode for flight " + card.flight.id + " (status " + card.status + ", JXL " + card.jxlLoaded + ")")
                    page.flickable.contentY = root.narrowTest ? 720 : 500
                } else if (phase === 10) {
                    const cards = root.descendants(page, "flightCard")
                    for (let card of cards) if (card.inViewport && (!card.revealed || card.opacity < 0.99)) throw new Error("A visible card failed to appear after scrolling")
                    const saved = backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-cards-narrow.png" : "starship-kirigami-cards.png"))
                    console.log(saved ? "SMOKE PASS: filters, mission transitions, reduced motion, scroll reveals, and 14 JPEG XL cards" : "SMOKE FAIL: screenshot capture")
                    backend.finish_test(saved)
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

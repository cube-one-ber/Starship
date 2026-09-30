pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
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
    readonly property bool smokeTest: Qt.application.arguments.indexOf("--smoke-test") >= 0
    readonly property bool narrowTest: Qt.application.arguments.indexOf("--narrow-test") >= 0
    readonly property var flights: JSON.parse(backend.flights_json)
    readonly property var schedule: JSON.parse(backend.schedule_json)
    readonly property var countdown: JSON.parse(backend.countdown_json)
    property string section: "archive"
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
        title: "Starship"
        titleIcon: "qrc:/icon.svg"
        modal: root.width < Kirigami.Units.gridUnit * 45
        collapsed: false
        isMenu: false
        actions: [
            Kirigami.Action { text: "Flight archive"; icon.name: "view-grid"; checkable: true; checked: root.section === "archive"; onTriggered: root.navigate(archivePage, "archive") },
            Kirigami.Action { text: "Next launch"; icon.name: "chronometer"; checkable: true; checked: root.section === "launch"; onTriggered: root.navigate(launchPage, "launch") },
            Kirigami.Action { text: "About Starship"; icon.name: "help-about"; checkable: true; checked: root.section === "about"; onTriggered: root.navigate(aboutPage, "about") }
        ]
        footer: Controls.Label {
            text: "Independent flight journal"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
            padding: Kirigami.Units.largeSpacing * 3
        }
    }
    pageStack.initialPage: archivePage

    Component {
        id: archivePage
        Kirigami.ScrollablePage {
            id: archive
            property alias searchControl: searchField
            property alias yearControl: yearFilter
            title: "Flight archive"
            padding: Kirigami.Units.largeSpacing * 3
            actions: [Kirigami.Action { text: "Refresh schedule"; icon.name: "view-refresh"; enabled: !backend.busy; onTriggered: backend.refresh() }]
            ColumnLayout {
                width: archive.availableWidth
                spacing: Kirigami.Units.largeSpacing * 3
                CountdownPanel { Layout.fillWidth: true; schedule: root.schedule; countdown: root.countdown; busy: backend.busy; errorMessage: backend.error_message; onRefreshRequested: backend.refresh() }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.Heading { text: "Flight history"; level: 1; type: Kirigami.Heading.Primary; Layout.fillWidth: true }
                        Controls.Label { text: root.flights.length + " flights"; color: Kirigami.Theme.disabledTextColor }
                    }
                    Controls.Label { text: "Discover the milestones and lessons from every integrated flight test."; color: Kirigami.Theme.disabledTextColor; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.SearchField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search flights…"
                        onTextChanged: backend.filter(yearFilter.currentText, text)
                    }
                    Controls.ComboBox {
                        id: yearFilter
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                        model: ["All years", "2026", "2025", "2024", "2023"]
                        Accessible.name: "Filter by year"
                        onCurrentTextChanged: backend.filter(currentText, searchField.text)
                    }
                }
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
                        model: root.flights
                        delegate: FlightCard {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            flight: modelData
                            useJxl: backend.supports_jxl
                            onActivated: flight => root.openFlight(flight)
                        }
                    }
                }
                Kirigami.PlaceholderMessage {
                    Layout.fillWidth: true
                    visible: root.flights.length === 0
                    text: "No flights found"
                    explanation: "Try another year or search term."
                    icon.name: "edit-find"
                    helpfulAction: Kirigami.Action { text: "Clear filters"; onTriggered: { searchField.text = ""; yearFilter.currentIndex = 0 } }
                }
                Controls.Label { Layout.fillWidth: true; text: "Latest flights first. Photography: Max Evans / NSF and SpaceX."; color: Kirigami.Theme.disabledTextColor; wrapMode: Text.WordWrap }
            }
        }
    }
    Component {
        id: missionPage
        Kirigami.ScrollablePage {
            id: mission
            required property var flight
            title: "Flight " + flight.id
            padding: Kirigami.Units.largeSpacing * 3
            actions: [Kirigami.Action { text: "Official report"; icon.name: "internet-services"; onTriggered: Qt.openUrlExternally(mission.flight.source) }]
            ColumnLayout {
                width: mission.availableWidth
                spacing: Kirigami.Units.largeSpacing * 3
                Photo { Layout.fillWidth: true; Layout.preferredHeight: Math.min(mission.width / 2, Kirigami.Units.gridUnit * 18); path: mission.flight.photo.path; useJxl: backend.supports_jxl; description: mission.flight.photo.alt }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 46
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.largeSpacing * 2
                    Kirigami.Heading { text: mission.flight.title; level: 1; type: Kirigami.Heading.Primary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Controls.Label { text: mission.flight.summary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Kirigami.FormLayout {
                        Layout.fillWidth: true
                        Controls.Label { Kirigami.FormData.label: "Launch date:"; text: new Date(mission.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMM yyyy") }
                        Controls.Label { Kirigami.FormData.label: "Outcome:"; text: mission.flight.outcome }
                        Controls.Label { Kirigami.FormData.label: "Milestone:"; text: mission.flight.milestone; wrapMode: Text.WordWrap }
                        Controls.Label { Kirigami.FormData.label: "Super Heavy:"; text: mission.flight.booster; wrapMode: Text.WordWrap }
                        Controls.Label { Kirigami.FormData.label: "Starship:"; text: mission.flight.ship; wrapMode: Text.WordWrap }
                    }
                    Kirigami.Separator { Layout.fillWidth: true }
                    Kirigami.Heading { text: "What happened"; level: 2 }
                    Repeater {
                        model: mission.flight.details
                        Kirigami.SelectableLabel { required property string modelData; text: modelData; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                    Controls.Label { text: mission.flight.photo.credit; color: Kirigami.Theme.disabledTextColor; Layout.fillWidth: true; wrapMode: Text.WordWrap }
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
                        Controls.Button { text: "Previous flight"; icon.name: "go-previous"; enabled: mission.flight.id > 1; onClicked: { mission.flight = JSON.parse(backend.mission(mission.flight.id - 1)); mission.flickable.contentY = 0 } }
                        Item { Layout.fillWidth: true }
                        Controls.Button { text: "Next flight"; icon.name: "go-next"; enabled: mission.flight.id < 14; onClicked: { mission.flight = JSON.parse(backend.mission(mission.flight.id + 1)); mission.flickable.contentY = 0 } }
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
            padding: Kirigami.Units.largeSpacing * 3
            ColumnLayout {
                width: launch.availableWidth
                spacing: Kirigami.Units.largeSpacing
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 42
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.largeSpacing
                    CountdownPanel { Layout.fillWidth: true; schedule: root.schedule; countdown: root.countdown; busy: backend.busy; errorMessage: backend.error_message; onRefreshRequested: backend.refresh() }
                    Photo { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 14; path: "/photos/hero"; useJxl: backend.supports_jxl; description: "Starship launching from Starbase" }
                    Controls.Label { Layout.fillWidth: true; text: "Launch timing may change as vehicles are tested and prepared. Only precise launch times are used for the countdown; provisional months and quarters are not treated as confirmed dates."; wrapMode: Text.WordWrap }
                }
            }
        }
    }
    Component {
        id: aboutPage
        Kirigami.ScrollablePage {
            id: about
            title: "About Starship"
            padding: Kirigami.Units.largeSpacing * 3
            ColumnLayout {
                width: about.availableWidth
                spacing: Kirigami.Units.largeSpacing
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 42
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.largeSpacing
                    Photo { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 14; path: "/photos/flight-13"; useJxl: backend.supports_jxl; description: "Starship at sunset, photographed by Max Evans" }
                    Kirigami.Heading { text: "Starship"; level: 1 }
                    Controls.Label { Layout.fillWidth: true; text: "SpaceX’s reusable transportation system in development, designed to carry people and cargo to Earth orbit, the Moon, Mars, and beyond. This independent journal follows each integrated flight test and the lessons learned along the way."; wrapMode: Text.WordWrap }
                    Controls.Button { text: "Starship at SpaceX"; icon.name: "internet-services"; onClicked: Qt.openUrlExternally("https://www.spacex.com/vehicles/starship") }
                    Kirigami.Separator { Layout.fillWidth: true }
                    Kirigami.Heading { text: "Sources and credits"; level: 2 }
                    Controls.Label { Layout.fillWidth: true; text: "Flight archive: SpaceX mission reports, reviewed September 29, 2026.\nPhotography: Max Evans / NSF and SpaceX.\nLaunch schedule: NextSpaceflight.\n\nUnaffiliated with SpaceX or NASASpaceflight."; wrapMode: Text.WordWrap; color: Kirigami.Theme.disabledTextColor }
                    Controls.Button { text: "Max Evans’s photo galleries"; icon.name: "camera-photo"; onClicked: Qt.openUrlExternally("https://maxevans.smugmug.com/Rockets") }
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
        id: smokeRunner
        property int phase: 0
        interval: 1600
        repeat: true
        running: root.smokeTest
        onTriggered: {
            try {
                if (phase === 0) {
                    if (!backend.appearance_ready()) throw new Error("Breeze style or KDE icons are missing")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-narrow.png" : "starship-kirigami-desktop.png"))) throw new Error("Could not capture archive")
                    if (root.flights.length !== 14) throw new Error("Archive must contain 14 flights")
                    let page = root.pageStack.currentItem
                    page.yearControl.currentIndex = 4
                    if (root.flights.length !== 2) throw new Error("Year control did not filter the archive")
                    page.yearControl.currentIndex = 0
                    page.searchControl.text = "first booster catch"
                    if (root.flights.length !== 1 || root.flights[0].id !== 5) throw new Error("Search control did not filter missions")
                    page.searchControl.text = ""
                    root.openFlight(JSON.parse(backend.mission(14)))
                } else if (phase === 1) {
                    if (root.pageStack.currentItem.flight.id !== 14) throw new Error("Mission page failed to open")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-mission-narrow.png" : "starship-kirigami-mission.png"))) throw new Error("Could not capture mission")
                    root.navigate(launchPage, "launch")
                } else if (phase === 2) {
                    if (root.pageStack.currentItem.title !== "Next launch") throw new Error("Launch navigation failed")
                    root.navigate(aboutPage, "about")
                } else if (phase === 3) {
                    if (root.pageStack.currentItem.title !== "About Starship") throw new Error("About navigation failed")
                    root.navigate(archivePage, "archive")
                } else if (phase === 4) {
                    const photos = root.descendants(root.pageStack.currentItem, "flightCard")
                    if (photos.length !== 14) throw new Error("Missing flight photos: " + photos.length)
                    for (let photo of photos) if (photo.status !== Image.Ready || !photo.jxlLoaded) throw new Error("JPEG XL image did not decode")
                    root.pageStack.currentItem.flickable.contentY = root.narrowTest ? 460 : 250
                } else if (phase === 5) {
                    const saved = backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-cards-narrow.png" : "starship-kirigami-cards.png"))
                    console.log(saved ? "SMOKE PASS: controls, navigation, and 14 JPEG XL cards" : "SMOKE FAIL: screenshot capture")
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

}

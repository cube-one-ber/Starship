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
    id: archive
    property alias searchControl: searchField
    property alias yearControl: yearFilter
    property var presentedFlights: []
    Component.onCompleted: presentedFlights = root.flights
    property alias resultsMotion: results
    property alias gridControl: flightGrid
    readonly property bool wideHeader: availableWidth > Kirigami.Units.gridUnit * 48
    readonly property var years: ["All years"].concat(Array.from(new Set(root.flightArchive.map(flight => flight.date.slice(0, 4)))).sort().reverse())
    property int viewIndex: 0
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
        spacing: archive.wideHeader ? 24 : 16
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
                scheduleState: root.scheduleState
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
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                SectionLabel { visible: archive.wideHeader; Layout.fillWidth: true; text: "01 / THE RECORD"; color: SpaceStyle.dim }
                SectionLabel {
                    visible: archive.wideHeader
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
            Controls.Label { visible: archive.wideHeader; font.family: SpaceStyle.sans; text: "From the first liftoff to orbit. Every test moves the horizon."; color: SpaceStyle.muted; wrapMode: Text.WordWrap; Layout.fillWidth: true }
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
                        model: archive.years
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
        Controls.TabBar {
            objectName: "archiveViews"
            Layout.fillWidth: true
            currentIndex: archive.viewIndex
            onCurrentIndexChanged: archive.viewIndex = currentIndex
            Controls.TabButton { text: "Flights" }
            Controls.TabButton { text: "Compare" }
            Controls.TabButton { text: "Milestones" }
        }
        ComparisonView {
            Layout.fillWidth: true
            visible: archive.viewIndex === 1 && archive.presentedFlights.length > 0
            flights: archive.presentedFlights
            onOpenRequested: flight => root.openFlight(flight)
        }
        MilestoneView {
            Layout.fillWidth: true
            visible: archive.viewIndex === 2
            flights: archive.presentedFlights.slice().reverse()
            onOpenRequested: flight => root.openFlight(flight)
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
                visible: archive.viewIndex === 0
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
        Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: (archive.viewIndex === 2 ? "Earliest flights first. " : "Latest flights first. ") + "Photography: Max Evans / NSF and SpaceX."; color: SpaceStyle.muted; wrapMode: Text.WordWrap }
    }
}

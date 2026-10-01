pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtCore as Core
import org.kde.kirigami as Kirigami
import org.starship.journal

Item {
    required property var root
    required property var backend
    function descendants(item, name) {
        let result = []
        if (item.objectName === name) result.push(item)
        if (item.children) for (let child of item.children) result = result.concat(descendants(child, name))
        return result
    }
    function checkPanelSpacing(item) {
        if (item.journalPanel === true && item.visible && item.width > 0 && item.contentItem) {
            if (Math.abs(item.contentItem.x - item.leftPadding) > 1
                || Math.abs(item.contentItem.y - item.topPadding) > 1
                || item.contentItem.width > item.availableWidth + 1) {
                throw new Error("Panel padding was overridden by the controls style: " + item.objectName)
            }
        }
        if (item.children) for (const child of item.children) checkPanelSpacing(child)
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
        interval: 1200
        repeat: true
        running: root.smokeTest
        onTriggered: {
            try {
                // The page stack is dynamic; each phase exercises its actual controls.
                const page = root.pageStack.currentItem
                checkPanelSpacing(page)
                if (phase === 0) {
                    if (!backend.appearance_ready()) throw new Error("Breeze style or KDE icons are missing")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-narrow.png" : "starship-kirigami-desktop.png"))) throw new Error("Could not capture archive")
                    if (root.flights.length !== 14 || root.flightArchive.length !== 14 || page.presentedFlights.length !== 14) throw new Error("Archive must contain 14 flights")
                    if (!root.narrowTest && page.gridControl.columns !== 3) throw new Error("Desktop archive did not retain three columns")
                    checkPanelSpacing(root.globalDrawer.contentItem)
                    if (!root.globalDrawer.modal && root.globalDrawer.width < 240) throw new Error("Navigation drawer is too narrow")
                    const firstCard = descendants(page, "flightCard")[0]
                    if (firstCard.mapToItem(page.flickable.contentItem, 0, 0).y + 100 >= page.flickable.height) throw new Error("Initial viewport must show the first flight card")
                    const launch = descendants(page, "launchPanel")[0]
                    launch.schedule = Object.assign({}, root.schedule, { launchAt: "2026-10-01T23:50:00Z" })
                    launch.countdown = { days: "01", hours: "02", minutes: "03", seconds: "04" }
                    if (launch.windowText !== "2026-10-01 · 23:50 UTC") throw new Error("Precise launch window must use a consistent UTC date and time")
                    launch.schedule = Qt.binding(function() { return root.schedule })
                    launch.countdown = Qt.binding(function() { return root.countdown })
                    if (root.narrowTest) {
                        if (!launch.collapsible || launch.detailsVisible) throw new Error("Narrow launch summary must start collapsed")
                        const toggle = descendants(launch, "launchDetailsToggle")[0]
                        toggle.clicked()
                        if (!launch.detailsVisible) throw new Error("Launch details did not expand")
                        toggle.clicked()
                        if (launch.detailsVisible) throw new Error("Launch details did not collapse")
                    }
                    page.yearControl.currentIndex = page.years.indexOf("2023")
                    if (root.flights.length !== 2) throw new Error("Year control did not filter the archive")
                    page.yearControl.currentIndex = 0
                    page.searchControl.text = "first booster catch"
                    if (root.flights.length !== 1 || root.flights[0].id !== 5) throw new Error("Search control did not filter missions")
                    if (root.narrowTest) page.flickable.contentY = Math.max(0, page.searchControl.mapToItem(page.flickable.contentItem, 0, 0).y - 24)
                } else if (phase === 1) {
                    if (page.presentedFlights.length !== 1 || page.presentedFlights[0].id !== 5 || page.resultsMotion.transitioning) throw new Error("Rapid filters did not settle on the latest results")
                    if (root.flightArchive.length !== 14 || root.latestFlightId !== 14) throw new Error("Filtering changed the archive overview or latest mission")
                    const clear = descendants(page, "clearFiltersButton")[0]
                    if (!clear || !clear.visible) throw new Error("Active filters must expose a clear action")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-filtered-narrow.png" : "starship-kirigami-filtered.png"))) throw new Error("Could not capture filtered archive")
                    page.searchControl.text = "no matching flight"
                } else if (phase === 2) {
                    if (page.presentedFlights.length !== 0) throw new Error("Empty filter results were not displayed")
                    const message = descendants(page, "emptyResults")[0]
                    if (!message || !message.visible) throw new Error("Empty results message is missing")
                    page.yearControl.currentIndex = page.years.indexOf("2023")
                    const clear = descendants(page, "clearFiltersButton")[0]
                    clear.clicked()
                    if (page.searchControl.text !== "" || page.yearControl.currentIndex !== 0 || page.filtersActive) throw new Error("Clear filters did not reset both controls")
                } else if (phase === 3) {
                    if (page.presentedFlights.length !== 14) throw new Error("Clearing filters did not restore the archive")
                    const card = descendants(page, "flightCard")[0]
                    card.forceActiveFocus()
                } else if (phase === 4) {
                    const card = descendants(page, "flightCard")[0]
                    const photo = descendants(card, "journalPhoto")[0]
                    const expectedScale = root.motionEnabled ? 1.045 : 1
                    if (!card.activeFocus || Math.abs(photo.imageScale - expectedScale) > 0.001) throw new Error("Keyboard focus did not produce the expected photo feedback")
                    card.activated(card.flight)
                } else if (phase === 5) {
                    if (page.flight.id !== 14) throw new Error("Card did not open the mission page")
                    const facts = descendants(page, "missionFacts")[0]
                    if (facts.padding !== 22 || facts.leftPadding !== 22) throw new Error("Mission facts lost their panel padding")
                    if (root.narrowTest && facts.contentItem.columns !== 1) throw new Error("Narrow mission facts must have a readable single column")
                    const headings = descendants(page, "missionLogHeading")
                    if (headings.length !== page.flight.details.length || headings.some((heading, index) => heading.text !== page.flight.details[index].heading)) throw new Error("Mission flight log headings are missing")
                    if (page.flight.landings.length !== 2 || page.flight.landings[1].coordinates !== "25°29′57.46″N · 155°25′39.13″W") throw new Error("Flight 14 geolocations are missing")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-mission-narrow.png" : "starship-kirigami-mission.png"))) throw new Error("Could not capture mission")
                    const timelineJump = descendants(page, "missionJump_timeline")[0]
                    if (!timelineJump) throw new Error("Mission section navigation is missing")
                    timelineJump.clicked()
                    if (page.flickable.contentY <= 0) throw new Error("Timeline navigation did not scroll the report")
                    const locations = descendants(page, "landingEstimate")
                    if (locations.length !== 2) throw new Error("Both Flight 14 location panels must render")
                    descendants(page, "missionJump_recovery")[0].clicked()
                    const recoveryTop = locations[0].mapToItem(page.flickable.contentItem, 0, 0).y
                    if (recoveryTop < page.flickable.contentY || recoveryTop >= page.flickable.contentY + page.flickable.height) throw new Error("Recovery navigation did not reach the landing panels")
                    page.flickable.contentY = Math.max(0, locations[1].mapToItem(page.flickable.contentItem, 0, 0).y - 90)
                } else if (phase === 6) {
                    const coordinates = descendants(page, "landingCoordinates")[1]
                    if (!coordinates || coordinates.text !== "25°29′57.46″N · 155°25′39.13″W" || coordinates.width > page.availableWidth) throw new Error("Ship 41 location did not render correctly")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-flight14-coordinates-narrow.png" : "starship-kirigami-flight14-coordinates.png"))) throw new Error("Could not capture Flight 14 coordinates")
                    page.changeFlight(13)
                    page.changeFlight(12)
                } else if (phase === 7) {
                    if (page.flight.id !== 12 || page.contentMotion.transitioning) throw new Error("Rapid mission changes did not settle on the latest flight")
                    const photo = descendants(page, "journalPhoto")[0]
                    if (!photo || photo.path !== page.flight.photo.path || photo.status !== Image.Ready) throw new Error("Mission photo did not follow the transition")
                    const coordinates = descendants(page, "landingCoordinates")[0]
                    const landing = descendants(page, "landingEstimate")[0]
                    const timeline = descendants(page, "missionTimeline")[0]
                    if (!landing || !landing.visible || !coordinates || coordinates.text !== "25°01′N · 94°10′W" || !timeline) throw new Error("Flight 12 research content is missing")
                    const analyses = descendants(page, "independentAnalysisEntry")
                    if (analyses.length !== 2 || analyses[0].width > page.availableWidth || analyses[0].height <= 0) throw new Error("Flight 12 analysis did not follow the mission change")
                    page.flickable.contentY = Math.max(0, landing.mapToItem(page.flickable.contentItem, 0, 0).y - 90)
                } else if (phase === 8) {
                    const coordinates = descendants(page, "landingCoordinates")[0]
                    if (coordinates.width > page.availableWidth || coordinates.height <= 0) throw new Error("Coordinate panel does not fit the mission page")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-coordinates-narrow.png" : "starship-kirigami-coordinates.png"))) throw new Error("Could not capture coordinate panel")
                    page.changeFlight(13)
                    const forced = root.forceReducedMotion
                    root.forceReducedMotion = true
                    if (page.flight.id !== 13 || page.contentMotion.opacity !== 1) throw new Error("Reducing motion did not finish the pending mission change")
                    root.forceReducedMotion = forced
                    const launchNav = descendants(root.globalDrawer.contentItem, "launchNavigation")[0]
                    if (!launchNav) throw new Error("Launch navigation is missing")
                    launchNav.clicked()
                } else if (phase === 9) {
                    if (page.title !== "Next launch") throw new Error("Launch navigation failed")
                    if (!descendants(root.globalDrawer.contentItem, "launchNavigation")[0].selected) throw new Error("Launch navigation did not become selected")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-launch-narrow.png" : "starship-kirigami-launch.png"))) throw new Error("Could not capture launch")
                    descendants(root.globalDrawer.contentItem, "aboutNavigation")[0].clicked()
                } else if (phase === 10) {
                    if (page.title !== "About Starship") throw new Error("About navigation failed")
                    if (!descendants(root.globalDrawer.contentItem, "aboutNavigation")[0].selected) throw new Error("About navigation did not become selected")
                    descendants(root.globalDrawer.contentItem, "archiveNavigation")[0].clicked()
                } else if (phase === 11) {
                    if (!descendants(root.globalDrawer.contentItem, "archiveNavigation")[0].selected) throw new Error("Archive navigation did not become selected")
                    const cards = descendants(page, "flightCard")
                    if (cards.length !== 14) throw new Error("Missing flight photos: " + cards.length)
                    for (let card of cards) {
                        if (card.status === Image.Error || !card.jxlLoaded) throw new Error("JPEG XL image did not decode for flight " + card.flight.id + " (status " + card.status + ", JXL " + card.jxlLoaded + ")")
                        // A recreated archive loads asynchronously; the runner's timeout bounds this wait.
                        if (card.status !== Image.Ready) return
                    }
                    page.flickable.contentY = root.narrowTest ? 720 : 500
                } else if (phase === 12) {
                    const cards = descendants(page, "flightCard")
                    for (let card of cards) if (card.inViewport && (!card.revealed || card.opacity < 0.99)) throw new Error("A visible card failed to appear after scrolling")
                    const saved = backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-cards-narrow.png" : "starship-kirigami-cards.png"))
                    if (!saved) throw new Error("Could not capture flight cards")
                    page.yearControl.currentIndex = page.years.indexOf("2024")
                    page.searchControl.text = "first booster catch"
                } else if (phase === 13) {
                    if (page.presentedFlights.length !== 1 || page.presentedFlights[0].id !== 5) throw new Error("Return-navigation filter setup failed")
                    page.flickable.contentY = Math.min(100, Math.max(0, page.flickable.contentHeight - page.flickable.height))
                    archiveSnapshot = { page: page, scroll: page.flickable.contentY, search: page.searchControl.text, year: page.yearControl.currentIndex }
                    root.openFlight(page.presentedFlights[0])
                } else if (phase === 14) {
                    if (page.flight.id !== 5) throw new Error("Filtered card did not open Flight 5")
                    if (!descendants(page, "missionJump_recovery")[0].visible || page.flight.landings[0].vehicle.indexOf("ring") < 0) throw new Error("Flight 5 discarded-ring location is missing")
                    const analyses = descendants(page, "independentAnalysisEntry")
                    if (analyses.length !== 2) throw new Error("Flight 5 analyses are missing")
                    descendants(page, "missionJump_analysis")[0].clicked()
                    const top = analyses[0].mapToItem(page.flickable.contentItem, 0, 0).y
                    if (top < page.flickable.contentY || top >= page.flickable.contentY + page.flickable.height) throw new Error("Analysis navigation did not reach the entries")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-analysis-narrow.png" : "starship-kirigami-analysis.png"))) throw new Error("Could not capture independent analysis")
                    descendants(page, "returnToArchive")[0].clicked()
                } else if (phase === 15) {
                    if (page !== archiveSnapshot.page || page.searchControl.text !== archiveSnapshot.search || page.yearControl.currentIndex !== archiveSnapshot.year || Math.abs(page.flickable.contentY - archiveSnapshot.scroll) > 2) throw new Error("Returning to the archive lost filters or scroll position")
                    page.clearFilters()
                    page.viewIndex = 1
                } else if (phase === 16) {
                    const comparison = descendants(page, "flightComparison")[0]
                    if (!comparison.visible || comparison.leftFlight.id !== 14 || comparison.rightFlight.id !== 13) throw new Error("Comparison did not initialize with the latest two flights (visible=" + comparison.visible + ", left=" + comparison.leftFlight.id + ", right=" + comparison.rightFlight.id + ", indices=" + comparison.leftControl.currentIndex + "/" + comparison.rightControl.currentIndex + ")")
                    comparison.rightControl.currentIndex = 7
                    if (comparison.rightFlight.id !== 7 || comparison.rightFlight.ship_outcome !== "lost") throw new Error("Comparison selection did not update vehicle outcomes")
                    const facts = descendants(comparison, "comparisonFact")
                    if (facts.length !== 6 || facts.some(fact => fact.width > page.availableWidth)) throw new Error("Comparison facts do not fit the page")
                    const selectors = descendants(comparison, "comparisonSelectors")[0]
                    if (selectors.columns !== (comparison.width < 540 ? 1 : 2)) throw new Error("Comparison selectors did not adapt to available width")
                    if (root.narrowTest && (comparison.leftControl.contentItem.truncated || comparison.rightControl.contentItem.truncated)) throw new Error("Narrow comparison flight choices are clipped")
                    page.flickable.contentY = Math.max(0, comparison.mapToItem(page.flickable.contentItem, 0, 0).y - 16)
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-compare-narrow.png" : "starship-kirigami-compare.png"))) throw new Error("Could not capture comparison")
                    page.viewIndex = 2
                } else if (phase === 17) {
                    const milestones = descendants(page, "flightMilestones")[0]
                    const entries = descendants(milestones, "milestoneEntry")
                    if (!milestones.visible || entries.length !== 14 || entries[0].modelData.id !== 1 || entries[13].modelData.id !== 14) throw new Error("Milestones are not chronological")
                    page.flickable.contentY = Math.max(0, milestones.mapToItem(page.flickable.contentItem, 0, 0).y - 16)
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-milestones-narrow.png" : "starship-kirigami-milestones.png"))) throw new Error("Could not capture milestones")
                    page.searchControl.text = "first booster catch"
                } else if (phase === 18) {
                    const milestones = descendants(page, "flightMilestones")[0]
                    const comparison = descendants(page, "flightComparison")[0]
                    if (milestones.flights.length !== 1 || milestones.flights[0].id !== 5 || comparison.leftFlight.id !== 5 || comparison.rightFlight.id !== 5) throw new Error("Alternate archive views did not follow filters")
                    page.searchControl.text = "no matching flight"
                } else if (phase === 19) {
                    if (!descendants(page, "emptyResults")[0].visible) throw new Error("Alternate archive views lack empty results")
                    const comparison = descendants(page, "flightComparison")[0]
                    if (comparison.leftFlight !== null || comparison.rightFlight !== null || comparison.leftControl.currentIndex !== -1 || comparison.rightControl.currentIndex !== -1) throw new Error("Empty comparison retained a flight selection")
                    root.openFlight(JSON.parse(backend.mission(1)))
                } else if (phase === 20) {
                    const summary = descendants(page, "debriefSummary")[0]
                    if (!summary || summary.flight.id !== 1 || summary.width > page.availableWidth) throw new Error("Debrief summary does not fit")
                    page.jumpTo("timeline")
                    if (page.activeSection !== "timeline" || !descendants(page, "missionJump_timeline")[0].checked) throw new Error("Mission shortcuts do not follow the active section")
                    page.flickable.contentY = 0
                    if (page.activeSection !== "overview") throw new Error("Scrolling did not reset the active section")
                    root.showArchive()
                    const archive = root.pageStack.currentItem
                    archive.clearFilters()
                    archive.viewIndex = 1
                    archive.flickable.contentY = 0
                } else if (phase === 21) {
                    const comparison = descendants(page, "flightComparison")[0]
                    page.flickable.contentY = Math.max(0, comparison.mapToItem(page.flickable.contentItem, 0, 0).y - 16)
                    comparison.leftControl.popup.open()
                } else if (phase === 22) {
                    const comparison = descendants(page, "flightComparison")[0]
                    const popup = comparison.leftControl.popup
                    if (!popup.visible || popup.contentItem.count !== 14 || popup.width > page.availableWidth) throw new Error("Flight selector popup does not fit or is missing options")
                    if (!backend.capture(backend.test_output_path(root.narrowTest ? "starship-kirigami-selector-narrow.png" : "starship-kirigami-selector.png"))) throw new Error("Could not capture flight selector popup")
                    popup.close()
                    console.log("SMOKE PASS: panel padding, adaptive navigation and facts, selector popups, compact launch details, archive visibility, section navigation, preserved archive state, mission transitions, reduced motion, research content, 14 JPEG XL cards, comparison, chronological milestones, filter continuity, and debrief summaries")
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

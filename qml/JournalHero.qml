pragma ComponentBehavior: Bound
import QtQuick
import org.starship.journal
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: hero
    property bool useJxl: false
    property bool motionEnabled: true
    property bool compact: false
    property int flightCount: 14
    signal exploreRequested()
    padding: 0
    background: Rectangle { color: SpaceStyle.surface; radius: SpaceStyle.radius }
    contentItem: Item {
        implicitHeight: Math.max(hero.compact ? 124 : 260, heroContent.implicitHeight + (hero.compact ? 32 : 48))
        clip: true
        Photo {
            anchors.fill: parent
            cornerRadius: SpaceStyle.radius
            cornerColor: SpaceStyle.voidColor
            motionEnabled: hero.motionEnabled
            restingScale: hero.motionEnabled ? 1.06 : 1
            NumberAnimation on restingScale { from: 1.06; to: 1; duration: Kirigami.Units.veryLongDuration * 2; running: hero.motionEnabled; easing.type: Easing.OutCubic }
            path: "/photos/hero"
            useJxl: hero.useJxl
            description: "Starship lifting off from Starbase, photographed by Max Evans"
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#e5090e16" }
                GradientStop { position: 0.6; color: "#73090e16" }
                GradientStop { position: 1; color: "#20090e16" }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#30090e16" }
                GradientStop { position: 0.6; color: "transparent" }
                GradientStop { position: 1; color: "#ed090e16" }
            }
        }
        AnimatedColumn {
            id: heroContent
            motionEnabled: hero.motionEnabled
            anchors.fill: parent
            anchors.margins: hero.compact ? 16 : 24
            spacing: hero.compact ? 6 : 7
            RowLayout {
                Layout.fillWidth: true
                Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: SpaceStyle.accent }
                SectionLabel { Layout.fillWidth: true; text: hero.compact ? "STARSHIP / " + hero.flightCount + " FLIGHTS" : "STARSHIP / FLIGHT ARCHIVE" }
                SectionLabel { visible: hero.width > 520; text: "EST. 2023"; color: "#b8c3d0" }
            }
            Item { Layout.fillHeight: true; visible: !hero.compact }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: -4
                Controls.Label {
                    Layout.fillWidth: true
                    text: hero.compact ? "The flight archive." : "Built for"
                    font.family: SpaceStyle.serif
                    font.pointSize: hero.compact ? 24 : 33
                    font.letterSpacing: -1.2
                    color: SpaceStyle.text
                    wrapMode: Text.WordWrap
                }
                Controls.Label {
                    Layout.fillWidth: true
                    visible: !hero.compact
                    text: "what comes next."
                    font.family: SpaceStyle.serif
                    font.italic: true
                    font.pointSize: hero.compact ? 24 : 31.5
                    font.letterSpacing: -1
                    color: SpaceStyle.softAccent
                    wrapMode: Text.WordWrap
                }
            }
            Controls.Label { font.family: SpaceStyle.sans;
                Layout.fillWidth: true
                visible: !hero.compact
                Layout.maximumWidth: 360
                text: "An independent record of Starship’s flights."
                font.pointSize: 10.5
                lineHeight: 1.35
                color: "#c4ceda"
                wrapMode: Text.WordWrap
            }
            Item { implicitHeight: 4; visible: !hero.compact }
            RowLayout {
                Layout.fillWidth: true
                JournalButton { font.family: SpaceStyle.sans;
                    id: explore
                    text: "Explore latest flight"
                    font.pointSize: 9.75
                    padding: 10
                    leftPadding: 18
                    rightPadding: 18
                    onClicked: hero.exploreRequested()
                    background: Rectangle {
                        radius: 24
                        antialiasing: true
                        gradient: Gradient { GradientStop { position: 0; color: explore.down ? "#cfa474" : explore.hovered ? "#ffe5c0" : "#f1d4ab" } GradientStop { position: 1; color: explore.down ? "#cfa474" : SpaceStyle.accent } }
                        border.color: explore.activeFocus ? SpaceStyle.text : "#40ffffff"
                        border.width: explore.activeFocus ? 2 : 1
                    }
                    contentItem: RowLayout {
                        Controls.Label { font.family: SpaceStyle.sans; text: explore.text; color: SpaceStyle.voidColor; font.weight: Font.DemiBold; font.pointSize: 9.75}
                        Kirigami.Icon { source: "go-next"; isMask: true; color: SpaceStyle.voidColor; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
                    }
                }
                Item { Layout.fillWidth: true }
            }

        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#35c4ceda"; radius: SpaceStyle.radius }
    }
}

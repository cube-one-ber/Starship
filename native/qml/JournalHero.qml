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
    signal exploreRequested()
    padding: 0
    background: Rectangle { color: SpaceStyle.surface; radius: SpaceStyle.radius }
    contentItem: Item {
        implicitHeight: hero.width < 440 ? 370 : 394
        clip: true
        Photo {
            anchors.fill: parent
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
            motionEnabled: hero.motionEnabled
            anchors.fill: parent
            anchors.margins: hero.width < 440 ? 24 : 32
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: SpaceStyle.accent }
                SectionLabel { Layout.fillWidth: true; text: "STARSHIP / FLIGHT JOURNAL" }
                SectionLabel { visible: hero.width > 520; text: "EST. 2023"; color: "#b8c3d0" }
            }
            Item { Layout.fillHeight: true }
            Controls.Label {
                Layout.fillWidth: true
                text: "Built for\nwhat comes next."
                font.family: SpaceStyle.serif
                font.pointSize: (hero.width < 440 ? 43 : 56) * 0.75
                font.letterSpacing: -1.3
                lineHeight: 0.98
                color: SpaceStyle.text
                wrapMode: Text.WordWrap
            }
            Controls.Label { font.family: SpaceStyle.sans;
                Layout.fillWidth: true
                Layout.maximumWidth: 360
                text: "The flights, the breakthroughs,\nand the journey beyond Earth."
                font.pointSize: 10.5
                lineHeight: 1.35
                color: "#c4ceda"
                wrapMode: Text.WordWrap
            }
            Item { implicitHeight: 4 }
            RowLayout {
                Layout.fillWidth: true
                Controls.Button { font.family: SpaceStyle.sans;
                    id: explore
                    text: "Explore latest flight"
                    font.pointSize: 9.75
                    padding: 12
                    onClicked: hero.exploreRequested()
                    background: Rectangle { radius: 6; color: explore.down ? "#cfa474" : explore.hovered ? "#f3d2a9" : SpaceStyle.accent }
                    contentItem: RowLayout {
                        Controls.Label { font.family: SpaceStyle.sans; text: explore.text; color: SpaceStyle.voidColor; font.weight: Font.DemiBold; font.pointSize: 9.75}
                        Kirigami.Icon { source: "go-next"; isMask: true; color: SpaceStyle.voidColor; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
                    }
                }
                Item { Layout.fillWidth: true }
            }
            Item { implicitHeight: 7 }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "#35ffffff" }
            RowLayout {
                Layout.fillWidth: true
                SectionLabel { text: "14 FLIGHTS / ONE HORIZON"; color: "#c4ceda"; font.pointSize: 6.75}
                Item { Layout.fillWidth: true }
                SectionLabel { visible: hero.width > 500; text: "STARBASE · TX"; color: "#c4ceda"; font.pointSize: 6.75}
            }
        }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#35c4ceda"; radius: SpaceStyle.radius }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import org.kde.kirigami as Kirigami
import org.starship.journal

Basic.ComboBox {
    id: choice
    font.family: SpaceStyle.sans
    hoverEnabled: true
    padding: 12
    spacing: 8
    implicitHeight: Math.max(42, implicitContentHeight + topPadding + bottomPadding)
    leftPadding: mirrored ? padding + indicator.width + spacing : padding
    rightPadding: mirrored ? padding : padding + indicator.width + spacing
    Accessible.description: displayText
    contentItem: Basic.Label {
        text: choice.displayText
        font: choice.font
        color: choice.enabled ? SpaceStyle.text : SpaceStyle.dim
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Kirigami.Icon {
        source: "go-down"
        isMask: true
        color: SpaceStyle.muted
        width: 16
        height: 16
        x: choice.mirrored ? choice.padding : choice.width - width - choice.padding
        y: (choice.height - height) / 2
    }
    background: Rectangle {
        implicitWidth: 160
        radius: 8
        color: choice.down || choice.hovered ? "#263748" : SpaceStyle.raised
        border.color: choice.visualFocus ? SpaceStyle.accent : SpaceStyle.line
        border.width: choice.visualFocus ? 2 : 1
    }
    delegate: Basic.ItemDelegate {
        id: option
        required property int index
        required property var modelData
        width: ListView.view.width
        implicitHeight: 40
        highlighted: choice.highlightedIndex === index
        hoverEnabled: true
        text: String(modelData)
        font: choice.font
        leftPadding: 12
        rightPadding: 12
        contentItem: Basic.Label {
            text: option.text
            font: option.font
            color: choice.currentIndex === option.index ? SpaceStyle.softAccent : SpaceStyle.text
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 6
            color: option.highlighted || option.hovered ? SpaceStyle.raised : "transparent"
            border.color: choice.currentIndex === option.index ? "#60eac38e" : "transparent"
        }
    }
    popup: Basic.Popup {
        y: choice.height + 6
        width: choice.width
        padding: 6
        topMargin: 12
        bottomMargin: 12
        implicitHeight: Math.min(list.contentHeight + topPadding + bottomPadding, 320)
        contentItem: ListView {
            id: list
            clip: true
            model: choice.delegateModel
            currentIndex: choice.highlightedIndex
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds
            Basic.ScrollIndicator.vertical: Basic.ScrollIndicator { }
        }
        background: Rectangle {
            color: SpaceStyle.surface
            radius: 10
            border.color: SpaceStyle.line
        }
    }
}

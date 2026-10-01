import QtQuick.Controls.Basic as Basic

// Desktop styles bind the four individual paddings to native widget metrics.
// Fully custom panels must use a base that honors the application's padding.
Basic.Control {
    readonly property bool journalPanel: true
}

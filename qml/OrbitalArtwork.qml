import QtQuick
import org.starship.journal

Canvas {
    id: artwork
    property color ink: SpaceStyle.cyan
    property bool grid: false
    Accessible.ignored: true
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onInkChanged: requestPaint()
    onGridChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = ink
        ctx.lineWidth = 1
        if (grid) {
            ctx.globalAlpha = 0.055
            for (let x = 24; x < width; x += 40) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke() }
            for (let y = 24; y < height; y += 40) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke() }
        }
        const cx = width * 0.76, cy = height * 0.38, radius = Math.min(width, height) * 0.42
        ctx.save()
        ctx.translate(cx, cy)
        ctx.rotate(-Math.PI / 7)
        ctx.globalAlpha = 0.2
        for (let i = 0; i < 3; i++) {
            const rx = radius * (1 + i * 0.4), ry = rx * 0.42
            ctx.beginPath(); ctx.ellipse(-rx, -ry, rx * 2, ry * 2); ctx.stroke()
        }
        ctx.globalAlpha = 0.1
        ctx.beginPath(); ctx.moveTo(-radius * 2, 0); ctx.lineTo(radius * 2, 0); ctx.stroke()
        ctx.globalAlpha = 0.35
        ctx.beginPath(); ctx.arc(0, 0, radius * 0.24, 0, Math.PI * 2); ctx.stroke()
        ctx.globalAlpha = 0.1
        ctx.beginPath(); ctx.arc(0, 0, radius * 0.3, 0, Math.PI * 2); ctx.stroke()
        ctx.globalAlpha = 0.8
        ctx.fillStyle = ink
        ctx.beginPath(); ctx.arc(radius * 1.4, 0, 3, 0, Math.PI * 2); ctx.fill()
        ctx.globalAlpha = 0.18
        ctx.beginPath(); ctx.arc(radius * 1.4, 0, 8, 0, Math.PI * 2); ctx.stroke()
        ctx.restore()
        ctx.globalAlpha = 0.35
        for (let i = 0; i < 19; i++) {
            const x = (i * 97 + 13) % Math.max(1, width)
            const y = (i * 61 + 31) % Math.max(1, height)
            ctx.fillRect(x, y, 1, 1)
        }
    }
}

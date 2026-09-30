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
        const cx = width * 0.76, cy = height * 0.4, radius = Math.min(width, height) * 0.34
        ctx.globalAlpha = 0.15
        for (let i = 0; i < 3; i++) {
            ctx.beginPath(); ctx.ellipse(cx - radius * (1 + i * 0.45), cy - radius * 0.65, radius * 2 * (1 + i * 0.45), radius * 1.3); ctx.stroke()
        }
        ctx.globalAlpha = 0.22
        ctx.beginPath(); ctx.moveTo(cx - radius * 1.9, cy); ctx.lineTo(cx + radius * 1.9, cy); ctx.stroke()
        ctx.beginPath(); ctx.moveTo(cx, cy - radius); ctx.lineTo(cx, cy + radius); ctx.stroke()
        ctx.globalAlpha = 0.8
        ctx.fillStyle = ink
        ctx.beginPath(); ctx.arc(cx + radius, cy, 2.5, 0, Math.PI * 2); ctx.fill()
        ctx.globalAlpha = 0.35
        for (let i = 0; i < 19; i++) {
            const x = (i * 97 + 13) % Math.max(1, width)
            const y = (i * 61 + 31) % Math.max(1, height)
            ctx.fillRect(x, y, 1, 1)
        }
    }
}

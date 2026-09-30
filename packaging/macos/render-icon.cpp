// Render the existing SVG for the macOS icon without a Quick Look GUI service.
#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <QSvgRenderer>
int main(int argc, char **argv) {
    qputenv("QT_QPA_PLATFORM", "offscreen");
    QGuiApplication app(argc, argv);
    if (argc != 3) return 1;
    QSvgRenderer renderer(QString::fromUtf8(argv[1]));
    if (!renderer.isValid()) return 1;
    QImage image(1024, 1024, QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);
    QPainter painter(&image);
    renderer.render(&painter);
    painter.end();
    return image.save(QString::fromUtf8(argv[2])) ? 0 : 1;
}

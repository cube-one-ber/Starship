#ifndef STARSHIP_QT_HELPERS_H
#define STARSHIP_QT_HELPERS_H
#include <QApplication>
#include "jxl_provider.h"
#include <QIcon>
#include <QFontDatabase>
#include <QDir>
#include <QFileInfo>
#include <QLibraryInfo>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QResource>
#include <QSaveFile>
#include <QStandardPaths>
#include <QStyle>
#include <QStringList>
#include <memory>
#include <vector>
namespace starship {
inline bool bundledFontsLoaded = false;
inline std::unique_ptr<QGuiApplication> newApplication(const QStringList &arguments) {
    // QApplication retains argc/argv, so their storage must outlive the app.
    static std::vector<QByteArray> storage;
    static std::vector<char *> pointers;
    static int argc;
    for (const auto &argument : arguments) storage.push_back(argument.toLocal8Bit());
    for (auto &argument : storage) pointers.push_back(argument.data());
    argc = static_cast<int>(pointers.size());
    pointers.push_back(nullptr);
    return std::make_unique<QApplication>(argc, pointers.data());
}
inline QString localBreezeImports() {
    const auto relative = QStringLiteral("target/runtime/usr/lib/qt6/qml");
    const QStringList candidates{QDir::current().filePath(relative),
        QDir(QCoreApplication::applicationDirPath()).filePath("../../" + relative)};
    for (const auto &path : candidates)
        if (QFile::exists(path + "/org/kde/breeze/qmldir")) return QDir(path).absolutePath();
    return {};
}
inline bool supportsJxl() { return true; }
inline void installImageProvider(QQmlApplicationEngine &engine) {
    const auto packagedImports = QDir(QCoreApplication::applicationDirPath()).filePath("qml");
    if (QDir(packagedImports).exists()) engine.addImportPath(packagedImports);
    if (const auto imports = localBreezeImports(); !imports.isEmpty()) engine.addImportPath(imports);
    engine.addImageProvider("jxl", new JxlProvider);
}
inline void exitApplication(int code) { QCoreApplication::exit(code); }
inline void configureApplication() {
    const QDir appDirectory(QCoreApplication::applicationDirPath());
    if (appDirectory.exists("plugins")) QCoreApplication::addLibraryPath(appDirectory.filePath("plugins"));
    if (const auto imports = localBreezeImports(); !imports.isEmpty()) QCoreApplication::addLibraryPath(QDir(imports).filePath("../plugins"));
    QCoreApplication::setApplicationName("Starship");
    QCoreApplication::setOrganizationName("StarshipJournal");
    QCoreApplication::setOrganizationDomain("starship.journal");
    QCoreApplication::setApplicationVersion("0.1.0");
    QGuiApplication::setDesktopFileName("org.starship.journal");
    // The Windows package includes KDE's binary icon theme; no system theme is needed.
    const auto iconResource = appDirectory.filePath("icons/breeze/breeze-icons.rcc");
    if (QFile::exists(iconResource)) QResource::registerResource(iconResource, "/icons/breeze");
    auto iconPaths = QIcon::themeSearchPaths();
    iconPaths.prepend(appDirectory.filePath("icons"));
    if (!iconPaths.contains(":/icons")) iconPaths.prepend(":/icons");
    QIcon::setThemeSearchPaths(iconPaths);
    QIcon::setThemeName("breeze");
    QIcon::setFallbackThemeName("breeze");
    QGuiApplication::setWindowIcon(QIcon(":/icon.svg"));
    bundledFontsLoaded = true;
    for (const auto &file : {"SF-Pro.ttf", "NewYork.ttf", "NewYorkItalic.ttf", "SF-Mono-Regular.otf", "SF-Mono-Semibold.otf"}) {
        const int id = QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/") + file);
        bundledFontsLoaded = bundledFontsLoaded && id >= 0 && !QFontDatabase::applicationFontFamilies(id).isEmpty();
    }
    QApplication::setFont(QFont(QStringLiteral("SF Pro"), 11));
    // KDE's theme plugins read the same application-scoped scheme path used by
    // KColorSchemeManager. Keep every control's color set in the bundled scheme.
    QCoreApplication::instance()->setProperty("KDE_COLOR_SCHEME_PATH", QStringLiteral(":/themes/Starship.colors"));
    QPalette flightPalette;
    flightPalette.setColor(QPalette::Window, QColor("#090e16"));
    flightPalette.setColor(QPalette::WindowText, QColor("#eef1f5"));
    flightPalette.setColor(QPalette::Base, QColor("#101925"));
    flightPalette.setColor(QPalette::AlternateBase, QColor("#162230"));
    flightPalette.setColor(QPalette::Text, QColor("#eef1f5"));
    flightPalette.setColor(QPalette::Button, QColor("#162230"));
    flightPalette.setColor(QPalette::ButtonText, QColor("#eef1f5"));
    flightPalette.setColor(QPalette::Highlight, QColor("#ecc08a"));
    flightPalette.setColor(QPalette::HighlightedText, QColor("#11151c"));
    flightPalette.setColor(QPalette::Link, QColor("#ecc08a"));
    flightPalette.setColor(QPalette::ToolTipBase, QColor("#162230"));
    flightPalette.setColor(QPalette::ToolTipText, QColor("#eef1f5"));
    flightPalette.setColor(QPalette::Disabled, QPalette::Text, QColor("#91a0b4"));
    flightPalette.setColor(QPalette::Disabled, QPalette::ButtonText, QColor("#91a0b4"));
    QApplication::setPalette(flightPalette);
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
#ifdef Q_OS_WIN
        // KDE's Windows guidance: use Breeze widgets through the desktop QML style.
        QApplication::setStyle("breeze");
        QQuickStyle::setStyle("org.kde.desktop");
#else
        const auto systemImports = QLibraryInfo::path(QLibraryInfo::QmlImportsPath);
        const bool breezeAvailable = !localBreezeImports().isEmpty() || QFile::exists(systemImports + "/org/kde/breeze/qmldir");
        QQuickStyle::setStyle(breezeAvailable ? "org.kde.breeze" : "org.kde.desktop");
#endif
    }

}
inline QString cachePath() {
    auto base = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    if (base.isEmpty()) base = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation)).filePath("starship-journal");
    return QDir(base).filePath("schedule.json");
}
inline bool saveJson(const QString &path, const QString &json) {
    if (!QDir().mkpath(QFileInfo(path).absolutePath())) return false;
    // QSaveFile replaces an existing cache atomically on both Windows and Unix.
    QSaveFile file(path);
    const auto bytes = json.toUtf8();
    return file.open(QIODevice::WriteOnly) && file.write(bytes) == bytes.size() && file.commit();
}
inline QString testOutputPath(const QString &name) {
    auto base = qEnvironmentVariable("STARSHIP_TEST_OUTPUT_DIR");
    if (base.isEmpty()) base = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QDir().mkpath(base);
    return QDir(base).absoluteFilePath(QFileInfo(name).fileName());
}
inline bool appearanceReady() {
#ifdef Q_OS_WIN
    return bundledFontsLoaded && QApplication::style()->objectName().compare("breeze", Qt::CaseInsensitive) == 0
        && QIcon::hasThemeIcon("chronometer") && QIcon::hasThemeIcon("dialog-ok-apply");
#else
    return bundledFontsLoaded;
#endif
}
inline int rootCount(const QQmlApplicationEngine &engine) { return engine.rootObjects().size(); }
inline bool captureWindow(const QString &path) {
    for (auto *window : QGuiApplication::topLevelWindows()) {
        if (auto *quick = qobject_cast<QQuickWindow *>(window); quick && quick->isVisible() && quick->title().startsWith("Starship"))
            return quick->grabWindow().save(path);
    }
    return false;
}
inline void quitApplication() { QCoreApplication::quit(); }
}

#endif

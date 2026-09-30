#ifndef STARSHIP_QT_HELPERS_H
#define STARSHIP_QT_HELPERS_H
#include <QApplication>
#include "jxl_provider.h"
#include <QIcon>
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
    const auto relative = QStringLiteral("native/runtime/usr/lib/qt6/qml");
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
    QCoreApplication::setApplicationName("Starship Journal");
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
    return QApplication::style()->objectName().compare("breeze", Qt::CaseInsensitive) == 0
        && QIcon::hasThemeIcon("chronometer") && QIcon::hasThemeIcon("dialog-ok-apply");
#else
    return true;
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

#![cfg_attr(all(windows, not(debug_assertions)), windows_subsystem = "windows")]

mod backend;
mod domain;
use cxx_qt::casting::Upcast;
use cxx_qt_lib::{QQmlApplicationEngine, QQmlEngine, QString, QStringList, QUrl};
use std::pin::Pin;

use backend::qobject as qt;
fn main() {
    let args: QStringList = std::env::args()
        .map(|arg| QString::from(arg.as_str()))
        .collect();
    let mut app = qt::newApplication(&args);
    qt::configureApplication();
    let mut engine = QQmlApplicationEngine::new();
    qt::installImageProvider(engine.as_mut().unwrap());
    let engine_ref = engine.as_mut().expect("QML engine initialization failed");
    let mut qml_engine: Pin<&mut QQmlEngine> = engine_ref.upcast_pin();
    qml_engine
        .as_mut()
        .on_quit(|_| qt::quitApplication())
        .release();
    engine.as_mut().unwrap().load(&QUrl::from(
        "qrc:/qt/qml/org/starship/journal/native/qml/Main.qml",
    ));
    if qt::rootCount(engine.as_ref().unwrap()) == 0 {
        eprintln!("Could not load the Starship Journal interface.");
        std::process::exit(1);
    }
    let exit_code = app
        .as_mut()
        .expect("Qt application initialization failed")
        .exec();
    std::process::exit(exit_code);
}

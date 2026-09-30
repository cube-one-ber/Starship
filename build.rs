use cxx_qt_build::{CxxQtBuilder, QmlFile, QmlModule};
fn main() {
    let windows = std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows");
    if windows {
        assert_eq!(
            std::env::var("CARGO_CFG_TARGET_ENV").as_deref(),
            Ok("gnu"),
            "Use scripts/build/build-windows.sh in MSYS2 UCRT64 to build the Windows app"
        );
        println!("cargo:rerun-if-changed=packaging/windows/app.rc");
        println!("cargo:rerun-if-changed=packaging/windows/app.ico");
        println!("cargo:rerun-if-changed=packaging/windows/app.manifest");
        println!("cargo:rerun-if-env-changed=WINDRES");
        let resource = std::path::PathBuf::from(std::env::var_os("OUT_DIR").unwrap())
            .join("starship-resource.o");
        let status = std::process::Command::new(
            std::env::var_os("WINDRES").unwrap_or_else(|| "windres".into()),
        )
        .args(["-i", "packaging/windows/app.rc", "-o"])
        .arg(&resource)
        .status()
        .expect("Install the MSYS2 UCRT64 binutils package (windres)");
        assert!(
            status.success(),
            "Failed to compile the Windows icon and manifest"
        );
        println!(
            "cargo:rustc-link-arg-bin=starship-journal={}",
            resource.display()
        );
    }
    println!("cargo:rerun-if-changed=src/cpp/qt_helpers.h");
    println!("cargo:rerun-if-changed=src/cpp/jxl_provider.h");
    let jxl = pkg_config::Config::new()
        .atleast_version("0.10")
        .probe("libjxl")
        .expect("Install libjxl development files");
    // SAFETY: only adds our header include directory to the compiler configuration.
    unsafe {
        CxxQtBuilder::new_qml_module(
            QmlModule::new("org.starship.journal")
                .qml_file("qml/Main.qml")
                .qml_file("qml/FlightCard.qml")
                .qml_file("qml/Photo.qml")
                .qml_file("qml/JournalHero.qml")
                .qml_file("qml/NavigationItem.qml")
                .qml_file("qml/FadeBehavior.qml")
                .qml_file("qml/AnimatedColumn.qml")
                .qml_file(QmlFile::from("qml/SpaceStyle.qml").singleton(true))
                .qml_file("qml/OrbitalArtwork.qml")
                .qml_file("qml/SectionLabel.qml")
                .qml_file("qml/MissionStat.qml")
                .qml_file("qml/MissionReport.qml")
                .qml_file("qml/CountdownPanel.qml"),
        )
        .qt_module("Network")
        .qt_module("Quick")
        .qt_module("QuickControls2")
        .qt_module("Widgets")
        .file("src/backend.rs")
        .qrc("resources/resources.qrc")
        .cc_builder(|cc| {
            cc.include("src/cpp");
            for path in &jxl.include_paths {
                cc.include(path);
            }
        })
        .build();
    }
    if windows {
        // MinGW scans import archives in order. These libraries are used by our
        // C++ helpers, so resolve them again after CXX-Qt's generated archive.
        for library in ["Qt6Quick", "Qt6Widgets", "jxl"] {
            println!("cargo:rustc-link-arg-bin=starship-journal=-l{library}");
        }
    }
}

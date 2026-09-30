use crate::domain::{self, Flight, Schedule};
use chrono::Utc;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QString;
use std::{path::PathBuf, pin::Pin, time::Duration};

#[cxx_qt::bridge(namespace = "starship")]
pub mod qobject {
    #[namespace = ""]
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qqmlapplicationengine.h");
        type QQmlApplicationEngine = cxx_qt_lib::QQmlApplicationEngine;
        include!("cxx-qt-lib/qguiapplication.h");
        type QGuiApplication = cxx_qt_lib::QGuiApplication;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
    }
    unsafe extern "C++" {
        include!("qt_helpers.h");
        fn newApplication(arguments: &QStringList) -> UniquePtr<QGuiApplication>;
        fn supportsJxl() -> bool;
        fn configureApplication();
        fn installImageProvider(engine: Pin<&mut QQmlApplicationEngine>);
        fn exitApplication(code: i32);
        fn rootCount(engine: &QQmlApplicationEngine) -> i32;
        fn captureWindow(path: &QString) -> bool;
        fn cachePath() -> QString;
        fn saveJson(path: &QString, json: &QString) -> bool;
        fn testOutputPath(name: &QString) -> QString;
        fn appearanceReady() -> bool;
        fn quitApplication();
    }
    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, flights_json)]
        #[qproperty(QString, schedule_json)]
        #[qproperty(QString, countdown_json)]
        #[qproperty(QString, schedule_state_json)]
        #[qproperty(QString, error_message)]
        #[qproperty(bool, busy)]
        #[qproperty(bool, supports_jxl)]
        type FlightBackend = super::FlightBackendRust;
        #[qinvokable]
        fn filter(self: Pin<&mut FlightBackend>, year: &QString, query: &QString);
        #[qinvokable]
        fn refresh(self: Pin<&mut FlightBackend>);
        #[qinvokable]
        fn tick(self: Pin<&mut FlightBackend>);
        #[qinvokable]
        fn mission(&self, id: i32) -> QString;
        #[qinvokable]
        fn finish_test(&self, success: bool);
        #[qinvokable]
        fn capture(&self, path: &QString) -> bool;
        #[qinvokable]
        fn test_output_path(&self, name: &QString) -> QString;
        #[qinvokable]
        fn appearance_ready(&self) -> bool;
    }
    impl cxx_qt::Threading for FlightBackend {}
}
fn cache_path() -> PathBuf {
    PathBuf::from(qobject::cachePath().to_string())
}
pub struct FlightBackendRust {
    flights_json: QString,
    schedule_json: QString,
    countdown_json: QString,
    schedule_state_json: QString,
    error_message: QString,
    busy: bool,
    supports_jxl: bool,
    all: Vec<Flight>,
    schedule: Schedule,
    schedule_origin: String,
}
impl Default for FlightBackendRust {
    fn default() -> Self {
        let all = domain::flights();
        let cached: Option<Schedule> = std::fs::read(cache_path())
            .ok()
            .and_then(|bytes| serde_json::from_slice::<Schedule>(&bytes).ok())
            .filter(|schedule| schedule.provider == "NextSpaceflight");
        let origin = if cached.is_some() {
            "cached"
        } else {
            "bundled"
        };
        let schedule = cached.unwrap_or_default();
        let state = domain::schedule_state(&schedule, origin, Utc::now());
        Self {
            flights_json: QString::from(serde_json::to_string(&all).unwrap().as_str()),
            schedule_json: QString::from(serde_json::to_string(&schedule).unwrap().as_str()),
            countdown_json: QString::from("null"),
            schedule_state_json: QString::from(serde_json::to_string(&state).unwrap().as_str()),
            error_message: QString::default(),
            busy: false,
            supports_jxl: qobject::supportsJxl(),
            all,
            schedule,
            schedule_origin: origin.into(),
        }
    }
}
impl qobject::FlightBackend {
    pub fn filter(mut self: Pin<&mut Self>, year: &QString, query: &QString) {
        let filtered =
            domain::filter_flights(&self.rust().all, &year.to_string(), &query.to_string());
        self.as_mut().set_flights_json(QString::from(
            serde_json::to_string(&filtered).unwrap().as_str(),
        ));
    }
    pub fn capture(&self, path: &QString) -> bool {
        qobject::captureWindow(path)
    }
    pub fn test_output_path(&self, name: &QString) -> QString {
        qobject::testOutputPath(name)
    }
    pub fn appearance_ready(&self) -> bool {
        qobject::appearanceReady()
    }
    pub fn finish_test(&self, success: bool) {
        qobject::exitApplication(if success { 0 } else { 1 });
    }
    pub fn mission(&self, id: i32) -> QString {
        let flight = self.rust().all.iter().find(|f| f.id as i32 == id);
        QString::from(serde_json::to_string(&flight).unwrap().as_str())
    }
    pub fn tick(mut self: Pin<&mut Self>) {
        let now = Utc::now();
        let state =
            domain::schedule_state(&self.rust().schedule, &self.rust().schedule_origin, now);
        let countdown = if state.stale {
            None
        } else {
            domain::countdown(&self.rust().schedule, now)
        };
        self.as_mut().set_schedule_state_json(QString::from(
            serde_json::to_string(&state).unwrap().as_str(),
        ));
        self.set_countdown_json(QString::from(
            serde_json::to_string(&countdown).unwrap().as_str(),
        ));
    }
    pub fn refresh(mut self: Pin<&mut Self>) {
        if *self.busy() {
            return;
        }
        self.as_mut().set_busy(true);
        self.as_mut().set_error_message(QString::default());
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let result = fetch_schedule();
            if let Ok(ref schedule) = result {
                if let Ok(json) = serde_json::to_string(schedule) {
                    let _ = qobject::saveJson(&qobject::cachePath(), &QString::from(json.as_str()));
                }
            }
            let _ = thread.queue(move |mut backend| {
                match result {
                    Ok(schedule) => {
                        backend.as_mut().set_schedule_json(QString::from(
                            serde_json::to_string(&schedule).unwrap().as_str(),
                        ));
                        backend.as_mut().rust_mut().schedule = schedule;
                        backend.as_mut().rust_mut().schedule_origin = "live".into();
                        backend.as_mut().tick();
                    }
                    Err(error) => {
                        if backend.rust().schedule_origin == "live" {
                            backend.as_mut().rust_mut().schedule_origin = "cached".into();
                        }
                        eprintln!("Schedule refresh: {error}");
                        backend.as_mut().set_error_message(QString::from(
                            "Unable to refresh. Showing the saved schedule.",
                        ));
                        backend.as_mut().tick();
                    }
                }
                backend.set_busy(false);
            });
        });
    }
}

#[cfg(test)]
mod portability_tests {
    use super::*;

    #[test]
    fn cache_write_replaces_existing_file_with_unicode_path() {
        let unique = Utc::now().timestamp_nanos_opt().unwrap();
        let directory =
            std::env::temp_dir().join(format!("starship cache 🛰 {}-{unique}", std::process::id()));
        let path = directory.join("nested/schedule.json");
        let qt_path = QString::from(path.to_str().unwrap());
        assert!(qobject::saveJson(
            &qt_path,
            &QString::from("{\"flight\":15}")
        ));
        assert!(qobject::saveJson(
            &qt_path,
            &QString::from("{\"flight\":16}")
        ));
        assert_eq!(std::fs::read_to_string(&path).unwrap(), "{\"flight\":16}");
        std::fs::remove_dir_all(directory).unwrap();
    }
}

fn fetch_schedule() -> Result<Schedule, String> {
    let client = reqwest::blocking::Client::builder()
        .timeout(Duration::from_secs(12))
        .user_agent("StarshipJournal/0.1")
        .build()
        .map_err(|e| e.to_string())?;
    let fetch_page = |url: &str| -> Result<serde_json::Value, String> {
        let html = client
            .get(url)
            .send()
            .map_err(|e| e.to_string())?
            .error_for_status()
            .map_err(|e| e.to_string())?
            .text()
            .map_err(|e| e.to_string())?;
        domain::parse_nextspaceflight(&html)
    };
    let data = fetch_page(domain::SCHEDULE_URL)?;
    let schedule = domain::normalize_schedule(&data, Utc::now())?;
    if schedule.source == domain::SCHEDULE_URL {
        return Ok(schedule);
    }
    let detail = fetch_page(&schedule.source)?;
    let verified = domain::normalize_schedule(&detail, Utc::now())?;
    if verified.source != schedule.source {
        return Err("NextSpaceflight launch details did not match".into());
    }
    Ok(verified)
}

#[cfg(test)]
mod tests {
    #[test]
    #[ignore = "Fetches the live NextSpaceflight website"]
    fn live_nextspaceflight_schedule() {
        let schedule = super::fetch_schedule().expect("Live NextSpaceflight refresh");
        assert_eq!(schedule.provider, "NextSpaceflight");
        assert!(schedule.source.starts_with("https://nextspaceflight.com/"));
        assert!(schedule.flight >= 15);
        println!(
            "Flight {}: {} ({})",
            schedule.flight, schedule.status, schedule.source
        );
    }
}

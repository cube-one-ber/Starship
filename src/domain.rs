use chrono::{DateTime, Datelike, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Photo {
    pub path: String,
    pub credit: String,
    pub url: String,
    pub alt: String,
}
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct FlightEvent {
    pub time: String,
    pub event: String,
}
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct LandingEstimate {
    pub vehicle: String,
    pub coordinates: String,
    pub latitude: f64,
    pub longitude: f64,
    pub precision: String,
    pub note: String,
    pub source: String,
}
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct IndependentAnalysis {
    pub title: String,
    pub kind: String,
    pub published: String,
    pub summary: String,
    pub source: String,
    pub context: Option<String>,
    pub context_label: String,
}
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct FlightDetail {
    pub heading: String,
    pub body: String,
}
#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum VehicleOutcome {
    Completed,
    Lost,
}
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Debrief {
    pub changed: String,
    pub worked: String,
    pub fell_short: String,
}
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Flight {
    pub id: u32,
    pub date: String,
    pub title: String,
    pub summary: String,
    pub booster: String,
    pub ship: String,
    pub milestone: String,
    pub outcome: String,
    pub details: Vec<FlightDetail>,
    pub booster_outcome: VehicleOutcome,
    pub ship_outcome: VehicleOutcome,
    pub debrief: Debrief,
    pub booster_id: String,
    pub ship_id: String,
    pub generation: String,
    pub launch_time: String,
    pub launch_site: String,
    pub payload: String,
    pub trajectory: String,
    pub timeline: Vec<FlightEvent>,
    pub landings: Vec<LandingEstimate>,
    pub analysis: Vec<IndependentAnalysis>,
    pub source: String,
    pub photo: Photo,
}
pub fn flights() -> Vec<Flight> {
    serde_json::from_str(include_str!("../resources/data/flights.json"))
        .expect("Bundled flight data is valid")
}
pub fn filter_flights(all: &[Flight], year: &str, query: &str) -> Vec<Flight> {
    let query = query.trim().to_lowercase();
    all.iter()
        .filter(|f| {
            (year == "All years" || f.date.starts_with(year))
                && (query.is_empty()
                    || format!(
                        "flight {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {}",
                        f.id,
                        f.title,
                        f.summary,
                        f.milestone,
                        f.booster,
                        f.ship,
                        f.booster_id,
                        f.ship_id,
                        f.generation,
                        f.payload,
                        f.trajectory,
                        f.launch_site,
                        f.details
                            .iter()
                            .map(|d| format!("{} {}", d.heading, d.body))
                            .collect::<Vec<_>>()
                            .join(" "),
                        f.debrief.changed,
                        f.debrief.worked,
                        f.debrief.fell_short,
                        f.timeline
                            .iter()
                            .map(|e| e.event.as_str())
                            .collect::<Vec<_>>()
                            .join(" "),
                        f.landings
                            .iter()
                            .map(|l| format!("{} {} {}", l.vehicle, l.coordinates, l.note))
                            .collect::<Vec<_>>()
                            .join(" "),
                        f.analysis
                            .iter()
                            .map(|a| format!(
                                "@mcrs987 TheSpaceEngineer {} {} {}",
                                a.title, a.kind, a.summary
                            ))
                            .collect::<Vec<_>>()
                            .join(" ")
                    )
                    .to_lowercase()
                    .contains(&query))
        })
        .cloned()
        .collect()
}
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Schedule {
    pub flight: u32,
    pub launch_at: Option<String>,
    pub precision: String,
    pub status: String,
    pub location: String,
    pub checked_at: String,
    pub source: String,
    pub provider: String,
}
impl Default for Schedule {
    fn default() -> Self {
        serde_json::from_str(include_str!("../resources/data/schedule.json"))
            .expect("Bundled schedule is valid")
    }
}
pub const SCHEDULE_URL: &str = "https://nextspaceflight.com/launches/?q=Starship";

// Three missed ten-minute refreshes make launch timing too old for a countdown.
pub const SCHEDULE_MAX_AGE_SECONDS: i64 = 30 * 60;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ScheduleState {
    pub origin: String,
    pub stale: bool,
    pub age_seconds: Option<i64>,
}

pub fn schedule_state(schedule: &Schedule, origin: &str, now: DateTime<Utc>) -> ScheduleState {
    // Older caches used date-only checks. Preserve their windows, but require a
    // successful refresh before treating their timing as current.
    let age = DateTime::parse_from_rfc3339(&schedule.checked_at)
        .ok()
        .map(|checked| now.timestamp() - checked.timestamp());
    ScheduleState {
        origin: origin.into(),
        stale: origin == "bundled"
            || age.is_none_or(|age| !(-60..=SCHEDULE_MAX_AGE_SECONDS).contains(&age)),
        age_seconds: age.map(|age| age.max(0)),
    }
}

// Parse serialized public-page data as JSON without executing website JavaScript.
pub fn parse_nextspaceflight(html: &str) -> Result<Value, String> {
    let mut records = String::new();
    for chunk in html.split("<script>self.__next_f.push(").skip(1) {
        let Some((json, _)) = chunk.split_once(")</script>") else {
            continue;
        };
        if let Ok(value) = serde_json::from_str::<Value>(json) {
            if let Some(text) = value[1].as_str() {
                records.push_str(text);
            }
        }
    }
    fn find(value: &Value) -> Option<Value> {
        if let Some(launches) = value.get("initialLaunches").and_then(Value::as_array) {
            return Some(serde_json::json!({"launches": launches}));
        }
        if value["name"].is_string()
            && value["net_precision"].is_string()
            && value["status"].is_object()
        {
            return Some(serde_json::json!({"launches": [value]}));
        }
        match value {
            Value::Array(values) => values.iter().find_map(find),
            Value::Object(values) => values.values().find_map(find),
            _ => None,
        }
    }
    for row in records.lines() {
        if let Some((_, json)) = row.split_once(':') {
            if let Ok(value) = serde_json::from_str::<Value>(json) {
                if let Some(data) = find(&value) {
                    return Ok(data);
                }
            }
        }
    }
    Err("NextSpaceflight page format was not recognized".into())
}

pub fn normalize_schedule(data: &Value, now: DateTime<Utc>) -> Result<Schedule, String> {
    let launches = data["launches"]
        .as_array()
        .ok_or("Invalid NextSpaceflight response")?;
    let default = Schedule::default();
    let mut candidates: Vec<(u32, &Value)> = launches
        .iter()
        .filter_map(|launch| {
            let name = launch["name"].as_str()?.to_lowercase();
            if !name.contains("starship") {
                return None;
            }
            let n = name
                .split("flight ")
                .nth(1)?
                .split_whitespace()
                .next()?
                .parse::<u32>()
                .ok()?;
            let status = launch["status"]["id"]
                .as_u64()
                .or_else(|| launch["status_id"].as_u64())?;
            (n >= default.flight && status <= 4).then_some((n, launch))
        })
        .collect();
    candidates.sort_by_key(|(n, _)| *n);
    let mut schedule = Schedule {
        launch_at: None,
        precision: "unknown".into(),
        status: "Awaiting launch window".into(),
        source: SCHEDULE_URL.into(),
        checked_at: now.to_rfc3339_opts(chrono::SecondsFormat::Secs, true),
        ..default
    };
    if let Some((n, launch)) = candidates.first() {
        schedule.flight = *n;
        if let Some(id) = launch["id"].as_u64().filter(|id| *id > 0) {
            schedule.source = format!("https://nextspaceflight.com/launches/details/{id}/");
        }
        if let Some(location) = launch["pad"]["location_name"]
            .as_str()
            .or_else(|| launch["pad_location_name"].as_str())
        {
            schedule.location = location.into();
        }
        let precision = launch["net_precision"]
            .as_str()
            .unwrap_or_default()
            .to_lowercase();
        let status = launch["status"]["id"]
            .as_u64()
            .or_else(|| launch["status_id"].as_u64())
            .unwrap_or(0);
        let net = launch["net"].as_str().unwrap_or_default();
        let date = DateTime::parse_from_rfc3339(net).ok();
        if ["second", "minute"].contains(&precision.as_str())
            && status == 2
            && date.is_some()
            && launch["liftoff_time_unconfirmed"].as_bool() == Some(false)
        {
            schedule.launch_at = Some(net.into());
            schedule.precision = precision;
            schedule.status = "Target launch time · subject to change".into();
        } else if status == 3 {
            schedule.status = "Countdown on hold".into();
        } else if status == 4 {
            schedule.status = "Launch scrubbed · awaiting new window".into();
        } else if let Some(date) = date {
            let date = date.with_timezone(&Utc);
            let window = match precision.as_str() {
                "month" => Some(date.format("%B %Y").to_string()),
                "quarter" => Some(format!("Q{} {}", (date.month() - 1) / 3 + 1, date.year())),
                "year" => Some(date.format("%Y").to_string()),
                "day" => Some(date.format("%-d %B %Y").to_string()),
                _ => None,
            };
            if let Some(window) = window {
                schedule.status = format!("NET {window} · awaiting launch time");
            }
        }
    }
    Ok(schedule)
}
#[derive(Debug, Serialize, PartialEq)]
pub struct Countdown {
    pub days: String,
    pub hours: String,
    pub minutes: String,
    pub seconds: String,
    pub elapsed: bool,
}
pub fn countdown(schedule: &Schedule, now: DateTime<Utc>) -> Option<Countdown> {
    if !["second", "minute"].contains(&schedule.precision.as_str())
        || schedule_state(schedule, "cached", now).stale
    {
        return None;
    }
    let target = DateTime::parse_from_rfc3339(schedule.launch_at.as_ref()?).ok()?;
    let seconds = (target.timestamp() - now.timestamp()).max(0);
    Some(Countdown {
        days: format!("{:02}", seconds / 86400),
        hours: format!("{:02}", seconds / 3600 % 24),
        minutes: format!("{:02}", seconds / 60 % 60),
        seconds: format!("{:02}", seconds % 60),
        elapsed: target <= now,
    })
}
#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    fn now() -> DateTime<Utc> {
        "2026-09-29T12:00:00Z".parse().unwrap()
    }
    fn feed(status: u32, precision: &str) -> Value {
        json!({"launches":[{"id":8403,"name":"Starship Flight 15","net":"2026-09-30T13:02:03Z","net_precision":precision,"status":{"id":status},"liftoff_time_unconfirmed":false}]})
    }
    #[test]
    fn archive_has_unique_flights() {
        let all = flights();
        assert_eq!(all.len(), 14);
        for n in 1..=14 {
            assert_eq!(all.iter().filter(|f| f.id == n).count(), 1)
        }
    }
    #[test]
    fn filters_combine_year_and_search() {
        let all = flights();
        assert_eq!(filter_flights(&all, "2023", "").len(), 2);
        assert_eq!(filter_flights(&all, "2024", "first booster catch")[0].id, 5);
        assert!(filter_flights(&all, "2023", "orbital flight").is_empty())
    }
    #[test]
    fn research_fields_are_complete_and_searchable() {
        let all = flights();
        for flight in &all {
            chrono::NaiveDate::parse_from_str(&flight.date, "%Y-%m-%d").unwrap();
            let time = flight.launch_time.strip_suffix(" UTC").unwrap();
            assert!(
                chrono::NaiveTime::parse_from_str(time, "%H:%M:%S")
                    .or_else(|_| chrono::NaiveTime::parse_from_str(time, "%H:%M"))
                    .is_ok()
            );
            assert!(
                flight
                    .details
                    .iter()
                    .all(|detail| !detail.heading.is_empty() && !detail.body.is_empty())
            );
            assert!(
                !flight.debrief.changed.is_empty()
                    && !flight.debrief.worked.is_empty()
                    && !flight.debrief.fell_short.is_empty()
            );
            assert!(flight.timeline.len() >= 3);
            assert!(!flight.booster_id.is_empty() && !flight.ship_id.is_empty());
            assert!(!flight.payload.is_empty() && !flight.trajectory.is_empty());
        }
        assert_eq!(filter_flights(&all, "All years", "S39")[0].id, 12);
        assert_eq!(
            filter_flights(&all, "All years", "Christmas Island")[0].id,
            13
        );
        assert_eq!(filter_flights(&all, "2024", "internal transfer")[0].id, 3);
        assert_eq!(
            filter_flights(&all, "All years", "@mcrs987")
                .iter()
                .map(|f| f.id)
                .collect::<Vec<_>>(),
            (1..=14).rev().collect::<Vec<_>>()
        );
    }
    #[test]
    fn independent_analysis_covers_each_flight_and_preserves_context() {
        let all = flights();
        let mut sources = std::collections::HashSet::new();
        assert_eq!(all.iter().map(|f| f.analysis.len()).sum::<usize>(), 26);
        for flight in &all {
            assert!(!flight.analysis.is_empty());
            for analysis in &flight.analysis {
                chrono::NaiveDate::parse_from_str(&analysis.published, "%Y-%m-%d").unwrap();
                assert!(!analysis.title.is_empty() && !analysis.summary.is_empty());
                assert!(sources.insert(&analysis.source));
                assert!(
                    analysis.source.starts_with("https://x.com/mcrs987/status/")
                        || analysis
                            .source
                            .starts_with("https://threadreaderapp.com/thread/")
                );
                assert_eq!(
                    analysis.context.is_some(),
                    !analysis.context_label.is_empty()
                );
            }
        }
        assert_eq!(filter_flights(&all, "All years", "FOIA")[0].id, 1);
        assert_eq!(filter_flights(&all, "All years", "perpendicular")[0].id, 3);
        assert_eq!(filter_flights(&all, "All years", "1,370")[0].id, 6);
        let ring = &all.iter().find(|f| f.id == 5).unwrap().landings[0];
        assert!(ring.vehicle.contains("ring"));
        assert_eq!(ring.precision, "Published estimate · ±0.5 km");
        let booster = &all.iter().find(|f| f.id == 13).unwrap().landings[0];
        assert!(booster.vehicle.contains("Booster 20"));
        assert_eq!(booster.coordinates, "25°56′43″N · 96°54′12″W");
    }
    #[test]
    fn impact_estimate_preserves_published_precision_and_identity() {
        let all = flights();
        let flight = all.iter().find(|f| f.id == 12).unwrap();
        let landing = flight.landings.first().unwrap();
        assert!((landing.latitude - (25.0 + 1.0 / 60.0)).abs() < 1e-9);
        assert!((landing.longitude + (94.0 + 10.0 / 60.0)).abs() < 1e-9);
        assert_eq!(landing.coordinates, "25°01′N · 94°10′W");
        assert_eq!(landing.precision, "Published estimate");
        assert!(landing.vehicle.contains("Booster 19") && landing.vehicle.contains("impact"));
        assert!(landing.source.ends_with("/2057988319842074718"));
        for location in all.iter().flat_map(|f| &f.landings) {
            assert!((-90.0..=90.0).contains(&location.latitude));
            assert!((-180.0..=180.0).contains(&location.longitude));
        }
        let orbital = all.iter().find(|f| f.id == 14).unwrap();
        assert_eq!(orbital.landings.len(), 2);
        let booster = &orbital.landings[0];
        let ship = &orbital.landings[1];
        assert!((booster.latitude - (25.0 + 52.0 / 60.0 + 47.0 / 3600.0)).abs() < 1e-9);
        assert!((booster.longitude + (96.0 + 46.0 / 60.0 + 36.0 / 3600.0)).abs() < 1e-9);
        assert!((ship.latitude - (25.0 + 29.0 / 60.0 + 57.46 / 3600.0)).abs() < 1e-9);
        assert!((ship.longitude + (155.0 + 25.0 / 60.0 + 39.13 / 3600.0)).abs() < 1e-9);
        assert_eq!(ship.coordinates, "25°29′57.46″N · 155°25′39.13″W");
        assert_eq!(ship.precision, "Independent geolocation");
        // These flights never reached their deployment phase.
        for id in [7, 8, 9] {
            let flight = all.iter().find(|f| f.id == id).unwrap();
            assert!(flight.payload.ends_with("not deployed"));
            assert!(
                !flight
                    .timeline
                    .iter()
                    .any(|e| e.event.contains("simulators deployed"))
            );
        }
    }
    #[test]
    fn placeholder_is_not_a_countdown() {
        for (s, p) in [(0, "Quarter"), (2, "Month"), (0, "Second"), (3, "Second")] {
            assert!(
                normalize_schedule(&feed(s, p), now())
                    .unwrap()
                    .launch_at
                    .is_none()
            )
        }
    }
    #[test]
    fn precise_time_counts_correctly() {
        let schedule = normalize_schedule(&feed(2, "Second"), now()).unwrap();
        assert_eq!(
            countdown(&schedule, now()).unwrap(),
            Countdown {
                days: "01".into(),
                hours: "01".into(),
                minutes: "02".into(),
                seconds: "03".into(),
                elapsed: false
            }
        )
    }
    #[test]
    fn expired_time_clamps_at_zero() {
        let checked = "2026-09-30T13:03:00Z".parse().unwrap();
        let schedule = normalize_schedule(&feed(2, "Second"), checked).unwrap();
        let c = countdown(&schedule, checked).unwrap();
        assert_eq!(c.days, "00");
        assert!(c.elapsed)
    }
    #[test]
    fn stale_legacy_and_future_checks_disable_countdowns() {
        let mut schedule = normalize_schedule(&feed(2, "Second"), now()).unwrap();
        assert_eq!(schedule.checked_at, "2026-09-29T12:00:00Z");
        assert!(
            countdown(
                &schedule,
                now() + chrono::Duration::seconds(SCHEDULE_MAX_AGE_SECONDS)
            )
            .is_some()
        );
        assert!(
            countdown(
                &schedule,
                now() + chrono::Duration::seconds(SCHEDULE_MAX_AGE_SECONDS + 1)
            )
            .is_none()
        );
        assert!(countdown(&schedule, now() - chrono::Duration::seconds(61)).is_none());
        assert!(schedule_state(&schedule, "bundled", now()).stale);
        for checked in ["2026-09-29", "invalid", ""] {
            schedule.checked_at = checked.into();
            assert!(countdown(&schedule, now()).is_none());
        }
    }
    #[test]
    fn missing_or_malformed_feed_is_safe() {
        assert!(normalize_schedule(&json!({}), now()).is_err());
        assert!(
            normalize_schedule(&json!({"launches":[]}), now())
                .unwrap()
                .launch_at
                .is_none()
        )
    }
    #[test]
    fn public_page_data_is_parsed_without_executing_scripts() {
        let list = json!(["$", "$L22", null, {"initialLaunches": feed(0, "Month")["launches"]}]);
        let record = format!("c:{list}\n");
        // Flight records can be split between transport chunks.
        let mid = record.len() / 2;
        let html = format!(
            "<script>alert('ignored')</script><script>self.__next_f.push({})</script><script>self.__next_f.push({})</script>",
            json!([1, &record[..mid]]),
            json!([1, &record[mid..]])
        );
        let parsed = parse_nextspaceflight(&html).unwrap();
        let schedule = normalize_schedule(&parsed, now()).unwrap();
        assert_eq!(
            schedule.source,
            "https://nextspaceflight.com/launches/details/8403/"
        );
        assert_eq!(schedule.status, "NET September 2026 · awaiting launch time");
        assert!(schedule.launch_at.is_none());
        let detail = format!("22:{}\n", feed(2, "Minute")["launches"][0]);
        let html = format!(
            "<script>self.__next_f.push({})</script>",
            json!([1, detail])
        );
        assert!(
            normalize_schedule(&parse_nextspaceflight(&html).unwrap(), now())
                .unwrap()
                .launch_at
                .is_some()
        );
        assert!(parse_nextspaceflight("<html>Access denied</html>").is_err());
        assert!(parse_nextspaceflight("<script>self.__next_f.push(bad)</script>").is_err());
    }
    #[test]
    fn unconfirmed_scrubbed_and_invalid_times_do_not_count_down() {
        for status in [0, 1, 3, 4, 5, 6, 7, 8, 9, 10] {
            assert!(
                normalize_schedule(&feed(status, "Second"), now())
                    .unwrap()
                    .launch_at
                    .is_none()
            );
        }
        let mut data = feed(2, "Second");
        data["launches"][0]["liftoff_time_unconfirmed"] = json!(true);
        assert!(
            normalize_schedule(&data, now())
                .unwrap()
                .launch_at
                .is_none()
        );
        data["launches"][0]
            .as_object_mut()
            .unwrap()
            .remove("liftoff_time_unconfirmed");
        assert!(
            normalize_schedule(&data, now())
                .unwrap()
                .launch_at
                .is_none()
        );
        data["launches"][0]["liftoff_time_unconfirmed"] = json!(false);
        data["launches"][0]["net"] = json!("invalid");
        assert!(
            normalize_schedule(&data, now())
                .unwrap()
                .launch_at
                .is_none()
        );
        assert_eq!(
            normalize_schedule(&feed(3, "Second"), now())
                .unwrap()
                .status,
            "Countdown on hold"
        );
        assert_eq!(
            normalize_schedule(&feed(4, "Second"), now())
                .unwrap()
                .status,
            "Launch scrubbed · awaiting new window"
        );
    }
    #[test]
    fn selects_next_numbered_flight_and_ignores_completed_launches() {
        let mut next = feed(0, "Month")["launches"][0].clone();
        next["name"] = json!("Starship Flight 16");
        next["id"] = json!(8405);
        let mut completed = feed(6, "Second")["launches"][0].clone();
        completed["name"] = json!("Starship Flight 14");
        let unrelated = json!({"name":"HLS LEO Demo", "status_id":0});
        let data =
            json!({"launches":[next, unrelated, completed, feed(0, "Month")["launches"][0]]});
        assert_eq!(normalize_schedule(&data, now()).unwrap().flight, 15);
        let data = json!({"launches":[{"id":8403,"name":"Starship Flight 15","status_id":0,"net_precision":"Month","net":"2026-10-31T23:59:59.000059Z","pad_location_name":"Starbase, Texas, USA"}]});
        let schedule = normalize_schedule(&data, now()).unwrap();
        assert_eq!(schedule.location, "Starbase, Texas, USA");
        assert_eq!(schedule.status, "NET October 2026 · awaiting launch time");
        assert_eq!(schedule.provider, "NextSpaceflight");
    }
}

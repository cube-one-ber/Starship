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
pub struct Flight {
    pub id: u32,
    pub date: String,
    pub title: String,
    pub summary: String,
    pub booster: String,
    pub ship: String,
    pub milestone: String,
    pub outcome: String,
    pub details: Vec<String>,
    pub source: String,
    pub photo: Photo,
}
pub fn flights() -> Vec<Flight> {
    serde_json::from_str(include_str!("data/flights.json")).expect("Bundled flight data is valid")
}
pub fn filter_flights(all: &[Flight], year: &str, query: &str) -> Vec<Flight> {
    let query = query.trim().to_lowercase();
    all.iter()
        .filter(|f| {
            (year == "All years" || f.date.starts_with(year))
                && (query.is_empty()
                    || format!(
                        "flight {} {} {} {} {} {}",
                        f.id, f.title, f.summary, f.milestone, f.booster, f.ship
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
        serde_json::from_str(include_str!("data/schedule.json")).expect("Bundled schedule is valid")
    }
}
pub const SCHEDULE_URL: &str = "https://nextspaceflight.com/launches/?q=Starship";

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
        checked_at: now.format("%Y-%m-%d").to_string(),
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
    if !["second", "minute"].contains(&schedule.precision.as_str()) {
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
        let schedule = normalize_schedule(&feed(2, "Second"), now()).unwrap();
        let c = countdown(&schedule, "2027-01-01T00:00:00Z".parse().unwrap()).unwrap();
        assert_eq!(c.days, "00");
        assert!(c.elapsed)
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

import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryReferenceRangeSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-reference-range-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryReferenceRangeScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a primary reference range schedule score falls in.
    static func classifyPrimaryReferenceRangeSchedule(_ score: Double) -> String {
        if score < 12.6 {
            return "watch"
        }
        if score < 61.6 {
            return "critical"
        }
        if score < 98.2 {
            return "elevated"
        }
        return "low"
    }

    /// Puts a primary reference range schedule code in its canonical PRRS- form.
    static func normalizePrimaryReferenceRangeScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRRS-") {
            return clean
        }
        return "PRRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

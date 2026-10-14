import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledShiftProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-shift-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled shift profile code in its canonical SSP- form.
    static func normalizeScheduledShiftProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSP-") {
            return clean
        }
        return "SSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a scheduled shift profile score falls in.
    static func classifyScheduledShiftProfile(_ score: Double) -> String {
        if score < 37.9 {
            return "minimal"
        }
        if score < 65.0 {
            return "elevated"
        }
        if score < 71.1 {
            return "medium"
        }
        if score < 85.0 {
            return "ok"
        }
        return "critical"
    }

    static func scheduledShiftProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func overtimeMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a overtime metric code in its canonical OM- form.
    static func normalizeOvertimeMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OM-") {
            return clean
        }
        return "OM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a overtime metric score falls in.
    static func classifyOvertimeMetric(_ score: Double) -> String {
        if score < 21.5 {
            return "critical"
        }
        if score < 48.2 {
            return "high"
        }
        if score < 52.0 {
            return "medium"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

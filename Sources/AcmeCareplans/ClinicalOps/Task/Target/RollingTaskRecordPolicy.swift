import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingTaskRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-task-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling task record code in its canonical RTR- form.
    static func normalizeRollingTaskRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RTR-") {
            return clean
        }
        return "RTR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingTaskRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a rolling task record score falls in.
    static func classifyRollingTaskRecord(_ score: Double) -> String {
        if score < 4.3 {
            return "minimal"
        }
        if score < 14.9 {
            return "high"
        }
        if score < 54.4 {
            return "watch"
        }
        if score < 74.5 {
            return "critical"
        }
        return "medium"
    }
}

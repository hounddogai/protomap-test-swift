import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a scheduled float pool assignment score falls in.
    static func classifyScheduledFloatPoolAssignment(_ score: Double) -> String {
        if score < 20.4 {
            return "low"
        }
        if score < 75.2 {
            return "high"
        }
        return "minimal"
    }

    /// Puts a scheduled float pool assignment code in its canonical SFPA- form.
    static func normalizeScheduledFloatPoolAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFPA-") {
            return clean
        }
        return "SFPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledFloatPoolAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-float-pool-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func scheduledFloatPoolAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}

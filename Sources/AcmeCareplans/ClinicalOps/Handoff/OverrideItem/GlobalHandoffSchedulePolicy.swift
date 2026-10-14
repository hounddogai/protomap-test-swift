import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalHandoffSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-handoff-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalHandoffScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a global handoff schedule score falls in.
    static func classifyGlobalHandoffSchedule(_ score: Double) -> String {
        if score < 51.6 {
            return "high"
        }
        if score < 59.6 {
            return "ok"
        }
        if score < 75.9 {
            return "elevated"
        }
        return "watch"
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func lenientProgramWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientProgramWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-program-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a lenient program window score falls in.
    static func classifyLenientProgramWindow(_ score: Double) -> String {
        if score < 12.9 {
            return "high"
        }
        if score < 24.3 {
            return "critical"
        }
        if score < 43.9 {
            return "medium"
        }
        if score < 54.5 {
            return "low"
        }
        return "elevated"
    }
}

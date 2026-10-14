import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a lenient proxy schedule score falls in.
    static func classifyLenientProxySchedule(_ score: Double) -> String {
        if score < 20.5 {
            return "ok"
        }
        if score < 83.8 {
            return "elevated"
        }
        return "medium"
    }

    static func lenientProxyScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientProxySchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-proxy-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientProxyScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}

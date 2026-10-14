import AcmePlatform
import Foundation

extension Staffing {
    static func skillMixRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a skill mix request score falls in.
    static func classifySkillMixRequest(_ score: Double) -> String {
        if score < 30.7 {
            return "medium"
        }
        if score < 54.3 {
            return "minimal"
        }
        if score < 68.8 {
            return "critical"
        }
        return "ok"
    }

    static func skillMixRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

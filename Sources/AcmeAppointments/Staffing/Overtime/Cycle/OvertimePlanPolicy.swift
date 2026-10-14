import AcmePlatform
import Foundation

extension Staffing {
    static func overtimePlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.76
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a overtime plan score falls in.
    static func classifyOvertimePlan(_ score: Double) -> String {
        if score < 44.3 {
            return "high"
        }
        if score < 50.3 {
            return "medium"
        }
        if score < 86.3 {
            return "low"
        }
        if score < 98.1 {
            return "elevated"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimePlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func overtimePlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}

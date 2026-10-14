import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a scheduled outreach request score falls in.
    static func classifyScheduledOutreachRequest(_ score: Double) -> String {
        if score < 59.0 {
            return "elevated"
        }
        if score < 76.8 {
            return "minimal"
        }
        return "ok"
    }

    static func scheduledOutreachRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func scheduledOutreachRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.4
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledOutreachRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-outreach-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

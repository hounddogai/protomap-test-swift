import AcmePlatform
import Foundation

extension CareManagement {
    static func lenientOutreachThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func lenientOutreachThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientOutreachThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-outreach-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a lenient outreach threshold score falls in.
    static func classifyLenientOutreachThreshold(_ score: Double) -> String {
        if score < 13.1 {
            return "high"
        }
        if score < 18.1 {
            return "minimal"
        }
        if score < 85.1 {
            return "watch"
        }
        return "medium"
    }
}

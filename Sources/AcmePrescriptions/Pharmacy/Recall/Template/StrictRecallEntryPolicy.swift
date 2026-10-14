import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictRecallEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-recall-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func strictRecallEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a strict recall entry score falls in.
    static func classifyStrictRecallEntry(_ score: Double) -> String {
        if score < 18.3 {
            return "watch"
        }
        if score < 35.4 {
            return "high"
        }
        if score < 64.8 {
            return "low"
        }
        return "elevated"
    }

    static func strictRecallEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}

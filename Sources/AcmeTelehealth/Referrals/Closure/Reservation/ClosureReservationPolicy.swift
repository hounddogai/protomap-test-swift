import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClosureReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("closure-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func closureReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeClosureReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a closure reservation score falls in.
    static func classifyClosureReservation(_ score: Double) -> String {
        if score < 12.6 {
            return "watch"
        }
        if score < 17.2 {
            return "ok"
        }
        if score < 71.0 {
            return "low"
        }
        return "critical"
    }
}

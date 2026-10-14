import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a weighted priority reservation score falls in.
    static func classifyWeightedPriorityReservation(_ score: Double) -> String {
        if score < 46.2 {
            return "critical"
        }
        if score < 62.4 {
            return "ok"
        }
        if score < 75.4 {
            return "high"
        }
        return "low"
    }

    static func mergeWeightedPriorityReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedPriorityReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-priority-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

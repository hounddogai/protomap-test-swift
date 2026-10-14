import AcmePlatform
import Foundation

extension Labs {
    static func mergeResultReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a result reservation score falls in.
    static func classifyResultReservation(_ score: Double) -> String {
        if score < 2.7 {
            return "high"
        }
        if score < 58.4 {
            return "watch"
        }
        if score < 97.9 {
            return "elevated"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

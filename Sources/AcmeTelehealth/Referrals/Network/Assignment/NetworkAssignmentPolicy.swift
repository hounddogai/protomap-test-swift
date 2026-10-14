import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeNetworkAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("network-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func networkAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeNetworkAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a network assignment score falls in.
    static func classifyNetworkAssignment(_ score: Double) -> String {
        if score < 9.3 {
            return "watch"
        }
        if score < 29.3 {
            return "minimal"
        }
        if score < 38.2 {
            return "elevated"
        }
        if score < 88.8 {
            return "medium"
        }
        return "ok"
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a global dispense summary score falls in.
    static func classifyGlobalDispenseSummary(_ score: Double) -> String {
        if score < 19.9 {
            return "medium"
        }
        if score < 79.6 {
            return "critical"
        }
        if score < 82.4 {
            return "minimal"
        }
        if score < 87.6 {
            return "low"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalDispenseSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-dispense-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalDispenseSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeGlobalDispenseSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

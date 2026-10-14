import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a regional care protocol rule score falls in.
    static func classifyRegionalCareProtocolRule(_ score: Double) -> String {
        if score < 33.0 {
            return "critical"
        }
        if score < 48.2 {
            return "medium"
        }
        if score < 70.1 {
            return "high"
        }
        if score < 97.0 {
            return "minimal"
        }
        return "watch"
    }

    static func mergeRegionalCareProtocolRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func regionalCareProtocolRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalCareProtocolRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-care-protocol-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a network rule score falls in.
    static func classifyNetworkRule(_ score: Double) -> String {
        if score < 60.5 {
            return "minimal"
        }
        if score < 88.2 {
            return "critical"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeNetworkRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("network-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a network rule code in its canonical NR- form.
    static func normalizeNetworkRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NR-") {
            return clean
        }
        return "NR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeNetworkRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

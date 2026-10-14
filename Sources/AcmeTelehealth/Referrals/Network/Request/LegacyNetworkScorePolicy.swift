import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a legacy network score code in its canonical LNS- form.
    static func normalizeLegacyNetworkScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LNS-") {
            return clean
        }
        return "LNS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyNetworkScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyNetworkScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-network-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyNetworkScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.09
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

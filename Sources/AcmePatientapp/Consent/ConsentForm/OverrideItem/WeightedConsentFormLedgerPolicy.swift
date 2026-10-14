import AcmePlatform
import Foundation

extension Consent {
    static func weightedConsentFormLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeWeightedConsentFormLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a weighted consent form ledger score falls in.
    static func classifyWeightedConsentFormLedger(_ score: Double) -> String {
        if score < 2.6 {
            return "high"
        }
        if score < 20.5 {
            return "low"
        }
        return "watch"
    }
}

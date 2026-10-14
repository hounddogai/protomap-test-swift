import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a weighted slot ledger score falls in.
    static func classifyWeightedSlotLedger(_ score: Double) -> String {
        if score < 9.2 {
            return "high"
        }
        if score < 33.2 {
            return "medium"
        }
        if score < 74.6 {
            return "watch"
        }
        if score < 76.4 {
            return "ok"
        }
        return "critical"
    }

    static func mergeWeightedSlotLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    static func defaultClosureLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.99
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeDefaultClosureLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default closure ledger score falls in.
    static func classifyDefaultClosureLedger(_ score: Double) -> String {
        if score < 2.2 {
            return "low"
        }
        if score < 12.2 {
            return "ok"
        }
        return "critical"
    }
}

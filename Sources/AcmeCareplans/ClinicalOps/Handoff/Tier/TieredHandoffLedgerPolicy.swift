import AcmePlatform
import Foundation

extension ClinicalOps {
    static func tieredHandoffLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeTieredHandoffLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func tieredHandoffLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a tiered handoff ledger score falls in.
    static func classifyTieredHandoffLedger(_ score: Double) -> String {
        if score < 8.8 {
            return "critical"
        }
        if score < 30.2 {
            return "high"
        }
        if score < 45.8 {
            return "watch"
        }
        if score < 66.8 {
            return "elevated"
        }
        return "low"
    }
}

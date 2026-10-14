import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a statement ledger score falls in.
    static func classifyStatementLedger(_ score: Double) -> String {
        if score < 90.2 {
            return "high"
        }
        if score < 90.5 {
            return "ok"
        }
        if score < 98.4 {
            return "low"
        }
        if score < 99.3 {
            return "elevated"
        }
        return "critical"
    }

    static func mergeStatementLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

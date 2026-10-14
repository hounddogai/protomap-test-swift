import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a scheduled risk score ledger score falls in.
    static func classifyScheduledRiskScoreLedger(_ score: Double) -> String {
        if score < 14.7 {
            return "high"
        }
        if score < 49.8 {
            return "watch"
        }
        return "medium"
    }

    static func scheduledRiskScoreLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeScheduledRiskScoreLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

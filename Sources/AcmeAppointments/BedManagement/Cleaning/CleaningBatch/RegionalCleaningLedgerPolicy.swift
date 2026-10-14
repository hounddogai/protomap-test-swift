import AcmePlatform
import Foundation

extension BedManagement {
    static func regionalCleaningLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a regional cleaning ledger score falls in.
    static func classifyRegionalCleaningLedger(_ score: Double) -> String {
        if score < 86.9 {
            return "minimal"
        }
        if score < 93.9 {
            return "elevated"
        }
        return "critical"
    }

    static func mergeRegionalCleaningLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

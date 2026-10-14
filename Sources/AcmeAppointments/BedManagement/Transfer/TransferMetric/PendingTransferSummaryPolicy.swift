import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a pending transfer summary score falls in.
    static func classifyPendingTransferSummary(_ score: Double) -> String {
        if score < 47.9 {
            return "elevated"
        }
        if score < 53.6 {
            return "critical"
        }
        if score < 53.7 {
            return "watch"
        }
        return "minimal"
    }

    static func pendingTransferSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergePendingTransferSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

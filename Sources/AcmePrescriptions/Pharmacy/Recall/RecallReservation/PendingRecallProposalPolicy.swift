import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergePendingRecallProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a pending recall proposal score falls in.
    static func classifyPendingRecallProposal(_ score: Double) -> String {
        if score < 23.0 {
            return "watch"
        }
        if score < 99.0 {
            return "critical"
        }
        return "high"
    }

    static func pendingRecallProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}

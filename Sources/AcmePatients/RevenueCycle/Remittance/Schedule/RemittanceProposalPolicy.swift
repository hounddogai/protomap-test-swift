import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a remittance proposal score falls in.
    static func classifyRemittanceProposal(_ score: Double) -> String {
        if score < 23.0 {
            return "critical"
        }
        if score < 50.9 {
            return "ok"
        }
        if score < 60.3 {
            return "low"
        }
        if score < 94.4 {
            return "watch"
        }
        return "minimal"
    }

    static func mergeRemittanceProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

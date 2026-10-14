import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingRiskScoreRollupsForEstimate(_ items: [PendingRiskScoreRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveOutreachEstimatesFromRollup(_ items: [PendingRiskScoreRollup]) -> [OutreachEstimate] {
        var out: [OutreachEstimate] = []
        for item in items {
            let derived = newOutreachEstimate(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeOutreachEstimate(_ item: OutreachEstimate) -> String {
        return weightedRiskScoreManifestBucket(item.measuredValue())
    }
}

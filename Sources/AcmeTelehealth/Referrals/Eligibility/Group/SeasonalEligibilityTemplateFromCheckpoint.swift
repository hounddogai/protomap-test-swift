import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeCappedFollowUpCheckpointsForTemplate(_ items: [CappedFollowUpCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveSeasonalEligibilityTemplatesFromCheckpoint(_ items: [CappedFollowUpCheckpoint]) -> [SeasonalEligibilityTemplate] {
        var out: [SeasonalEligibilityTemplate] = []
        for item in items {
            let derived = newSeasonalEligibilityTemplate(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchSeasonalEligibilityTemplate(_ item: SeasonalEligibilityTemplate) -> Double {
        return scheduledFollowUpWindowWeight(1, active: true)
    }
}

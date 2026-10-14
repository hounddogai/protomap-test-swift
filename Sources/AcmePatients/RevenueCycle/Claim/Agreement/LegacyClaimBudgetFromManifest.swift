import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLegacyClaimManifestsForBudget(_ items: [LegacyClaimManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyClaimBudgetsFromManifest(_ items: [LegacyClaimManifest]) -> [LegacyClaimBudget] {
        var out: [LegacyClaimBudget] = []
        for item in items {
            let derived = newLegacyClaimBudget(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeLegacyClaimBudget(_ item: LegacyClaimBudget) -> Double {
        return manualClaimMilestoneWeight(6, active: true)
    }
}

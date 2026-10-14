import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeScheduledHandoffMilestonesForTier(_ items: [ScheduledHandoffMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRegionalAlertTiersFromMilestone(_ items: [ScheduledHandoffMilestone]) -> [RegionalAlertTier] {
        var out: [RegionalAlertTier] = []
        for item in items {
            let derived = newRegionalAlertTier(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreRegionalAlertTier(_ item: RegionalAlertTier) -> String {
        return classifyTieredHandoffOverride(item.effectiveLoad())
    }
}

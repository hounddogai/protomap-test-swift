import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyFormularyRollupsForMilestone(_ items: [LegacyFormularyRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveDefaultInteractionMilestonesFromRollup(_ items: [LegacyFormularyRollup]) -> [DefaultInteractionMilestone] {
        var out: [DefaultInteractionMilestone] = []
        for item in items {
            let derived = newDefaultInteractionMilestone(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyDefaultInteractionMilestoneExtra(_ item: DefaultInteractionMilestone) -> Double {
        return formularyMetricWeight(9, active: true)
    }
}

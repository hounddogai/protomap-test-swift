import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRegionalSlotOverridesForBundle(_ items: [RegionalSlotOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveDefaultClosureBundlesFromOverride(_ items: [RegionalSlotOverride]) -> [DefaultClosureBundle] {
        var out: [DefaultClosureBundle] = []
        for item in items {
            let derived = newDefaultClosureBundle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeDefaultClosureBundle(_ item: DefaultClosureBundle) -> Double {
        return slotMilestoneWeight(7, active: true)
    }
}

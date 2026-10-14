import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePendingSkillMixPreferencesForTier(_ items: [PendingSkillMixPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCappedShiftTiersFromPreference(_ items: [PendingSkillMixPreference]) -> [CappedShiftTier] {
        var out: [CappedShiftTier] = []
        for item in items {
            let derived = newCappedShiftTier(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveCappedShiftTier(_ item: CappedShiftTier) -> String {
        return classifyTieredSkillMixMilestone(item.projectedExposure())
    }
}

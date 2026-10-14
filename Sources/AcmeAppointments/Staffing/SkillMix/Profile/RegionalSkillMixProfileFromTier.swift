import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePendingFloatPoolTiersForProfile(_ items: [PendingFloatPoolTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRegionalSkillMixProfilesFromTier(_ items: [PendingFloatPoolTier]) -> [RegionalSkillMixProfile] {
        var out: [RegionalSkillMixProfile] = []
        for item in items {
            let derived = newRegionalSkillMixProfile(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalSkillMixProfile(_ item: RegionalSkillMixProfile) -> String {
        return classifyFloatPoolProfile(item.measuredValue())
    }
}

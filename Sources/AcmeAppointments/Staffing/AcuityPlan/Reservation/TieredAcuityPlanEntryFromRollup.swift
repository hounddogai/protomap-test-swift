import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackSkillMixRollupsForEntry(_ items: [FallbackSkillMixRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveTieredAcuityPlanEntriesFromRollup(_ items: [FallbackSkillMixRollup]) -> [TieredAcuityPlanEntry] {
        var out: [TieredAcuityPlanEntry] = []
        for item in items {
            let derived = newTieredAcuityPlanEntry(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectTieredAcuityPlanEntry(_ item: TieredAcuityPlanEntry) -> String {
        return scheduledSkillMixRollupBucket(item.weightedTotal())
    }
}

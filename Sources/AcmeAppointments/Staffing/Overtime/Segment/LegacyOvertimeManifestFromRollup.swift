import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackSkillMixRollupsForManifest(_ items: [FallbackSkillMixRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveLegacyOvertimeManifestsFromRollup(_ items: [FallbackSkillMixRollup]) -> [LegacyOvertimeManifest] {
        var out: [LegacyOvertimeManifest] = []
        for item in items {
            let derived = newLegacyOvertimeManifest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignLegacyOvertimeManifest(_ item: LegacyOvertimeManifest) -> String {
        return skillMixEntryBucket(item.netValue())
    }
}

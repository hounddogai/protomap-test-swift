import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalSkillMixQuotasForCheckpoint(_ items: [RegionalSkillMixQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveLenientCredentialCheckpointsFromQuota(_ items: [RegionalSkillMixQuota]) -> [LenientCredentialCheckpoint] {
        var out: [LenientCredentialCheckpoint] = []
        for item in items {
            let derived = newLenientCredentialCheckpoint(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLenientCredentialCheckpoint(_ item: LenientCredentialCheckpoint) -> String {
        return skillMixMilestoneBucket(item.measuredValue())
    }
}

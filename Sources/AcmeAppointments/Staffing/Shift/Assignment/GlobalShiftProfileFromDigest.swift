import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePendingSkillMixDigestsForProfile(_ items: [PendingSkillMixDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveGlobalShiftProfilesFromDigest(_ items: [PendingSkillMixDigest]) -> [GlobalShiftProfile] {
        var out: [GlobalShiftProfile] = []
        for item in items {
            let derived = newGlobalShiftProfile(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeGlobalShiftProfile(_ item: GlobalShiftProfile) -> String {
        return cappedSkillMixManifestBucket(item.projectedExposure())
    }
}

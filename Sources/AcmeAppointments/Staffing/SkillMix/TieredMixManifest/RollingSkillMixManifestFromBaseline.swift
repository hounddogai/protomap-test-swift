import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialBaselinesForManifest(_ items: [CredentialBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRollingSkillMixManifestsFromBaseline(_ items: [CredentialBaseline]) -> [RollingSkillMixManifest] {
        var out: [RollingSkillMixManifest] = []
        for item in items {
            let derived = newRollingSkillMixManifest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchRollingSkillMixManifest(_ item: RollingSkillMixManifest) -> String {
        return normalizeLegacyCredentialSlotCode(item.code)
    }
}

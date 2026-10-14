import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolOverridesForProfile(_ items: [CareProtocolOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveFallbackCareProtocolProfilesFromOverride(_ items: [CareProtocolOverride]) -> [FallbackCareProtocolProfile] {
        var out: [FallbackCareProtocolProfile] = []
        for item in items {
            let derived = newFallbackCareProtocolProfile(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileFallbackCareProtocolProfile(_ item: FallbackCareProtocolProfile) -> Double {
        return manualCareProtocolMappingWeight(3, active: true)
    }
}

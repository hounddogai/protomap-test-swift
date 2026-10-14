import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackDenialPoliciesForProfile(_ items: [FallbackDenialPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveDenialProfilesFromPolicy(_ items: [FallbackDenialPolicy]) -> [DenialProfile] {
        var out: [DenialProfile] = []
        for item in items {
            let derived = newDenialProfile(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateDenialProfile(_ item: DenialProfile) -> String {
        return normalizeDenialThresholdCode(item.code)
    }
}

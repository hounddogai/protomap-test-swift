import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialProfilesForPreference(_ items: [DenialProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePendingAuthorizationPreferencesFromProfile(_ items: [DenialProfile]) -> [PendingAuthorizationPreference] {
        var out: [PendingAuthorizationPreference] = []
        for item in items {
            let derived = newPendingAuthorizationPreference(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcilePendingAuthorizationPreference(_ item: PendingAuthorizationPreference) -> Double {
        return denialVarianceWeight(3, active: true)
    }
}

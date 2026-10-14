import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveEligibilityPreferencesForClaim(_ items: [AdaptiveEligibilityPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveAdaptiveReferralClaimsFromPreference(_ items: [AdaptiveEligibilityPreference]) -> [AdaptiveReferralClaim] {
        var out: [AdaptiveReferralClaim] = []
        for item in items {
            let derived = newAdaptiveReferralClaim(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankAdaptiveReferralClaim(_ item: AdaptiveReferralClaim) -> Double {
        return adaptiveEligibilityPreferenceWeight(6, active: true)
    }
}

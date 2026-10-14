import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityPreferencesForClaim(_ items: [EligibilityPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func derivePrimaryEligibilityClaimsFromPreference(_ items: [EligibilityPreference]) -> [PrimaryEligibilityClaim] {
        var out: [PrimaryEligibilityClaim] = []
        for item in items {
            let derived = newPrimaryEligibilityClaim(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPrimaryEligibilityClaim(_ item: PrimaryEligibilityClaim) -> String {
        return eligibilityPreferenceBucket(item.effectiveVolume())
    }
}

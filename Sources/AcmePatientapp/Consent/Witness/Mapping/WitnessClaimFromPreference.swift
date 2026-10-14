import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormPreferencesForClaim(_ items: [ConsentFormPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveWitnessClaimsFromPreference(_ items: [ConsentFormPreference]) -> [WitnessClaim] {
        var out: [WitnessClaim] = []
        for item in items {
            let derived = newWitnessClaim(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWitnessClaim(_ item: WitnessClaim) -> Double {
        return consentFormReviewWeight(2, active: true)
    }
}

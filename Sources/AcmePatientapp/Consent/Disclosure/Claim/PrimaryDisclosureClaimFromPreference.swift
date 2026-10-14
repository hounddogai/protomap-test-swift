import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosurePreferencesForClaim(_ items: [DisclosurePreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryDisclosureClaimsFromPreference(_ items: [DisclosurePreference]) -> [PrimaryDisclosureClaim] {
        var out: [PrimaryDisclosureClaim] = []
        for item in items {
            let derived = newPrimaryDisclosureClaim(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settlePrimaryDisclosureClaim(_ item: PrimaryDisclosureClaim) -> Double {
        return disclosureAgreementWeight(5, active: true)
    }
}

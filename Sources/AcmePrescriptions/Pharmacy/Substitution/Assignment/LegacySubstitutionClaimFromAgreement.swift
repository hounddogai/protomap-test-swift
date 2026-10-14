import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedFormularyAgreementsForClaim(_ items: [WeightedFormularyAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveLegacySubstitutionClaimsFromAgreement(_ items: [WeightedFormularyAgreement]) -> [LegacySubstitutionClaim] {
        var out: [LegacySubstitutionClaim] = []
        for item in items {
            let derived = newLegacySubstitutionClaim(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacySubstitutionClaim(_ item: LegacySubstitutionClaim) -> String {
        return cappedFormularyReviewBucket(item.effectiveTotal())
    }
}

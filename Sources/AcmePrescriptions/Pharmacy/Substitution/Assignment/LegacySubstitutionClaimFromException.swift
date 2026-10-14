import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSeasonalSubstitutionExceptionsForClaim(_ items: [SeasonalSubstitutionException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveLegacySubstitutionClaimsFromException(_ items: [SeasonalSubstitutionException]) -> [LegacySubstitutionClaim] {
        var out: [LegacySubstitutionClaim] = []
        for item in items {
            let derived = newLegacySubstitutionClaim(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileLegacySubstitutionClaim(_ item: LegacySubstitutionClaim) -> String {
        return classifySeasonalSubstitutionQuota(item.effectiveTotal())
    }
}

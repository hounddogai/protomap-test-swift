import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalRoundingRequestsForClaim(_ items: [SeasonalRoundingRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func derivePrimaryTaskClaimsFromRequest(_ items: [SeasonalRoundingRequest]) -> [PrimaryTaskClaim] {
        var out: [PrimaryTaskClaim] = []
        for item in items {
            let derived = newPrimaryTaskClaim(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyPrimaryTaskClaim(_ item: PrimaryTaskClaim) -> Double {
        return seasonalRoundingRequestWeight(4, active: true)
    }
}

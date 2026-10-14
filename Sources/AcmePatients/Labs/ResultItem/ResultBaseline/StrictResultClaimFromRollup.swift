import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSeasonalAccessionRollupsForClaim(_ items: [SeasonalAccessionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveStrictResultClaimsFromRollup(_ items: [SeasonalAccessionRollup]) -> [StrictResultClaim] {
        var out: [StrictResultClaim] = []
        for item in items {
            let derived = newStrictResultClaim(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planStrictResultClaim(_ item: StrictResultClaim) -> String {
        return seasonalAccessionRollupBucket(item.weightedTotal())
    }
}

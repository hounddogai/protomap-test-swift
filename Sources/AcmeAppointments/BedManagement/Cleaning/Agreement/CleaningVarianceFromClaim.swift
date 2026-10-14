import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedBedBoardClaimsForVariance(_ items: [WeightedBedBoardClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveCleaningVariancesFromClaim(_ items: [WeightedBedBoardClaim]) -> [CleaningVariance] {
        var out: [CleaningVariance] = []
        for item in items {
            let derived = newCleaningVariance(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchCleaningVariance(_ item: CleaningVariance) -> String {
        return normalizeStrictBedBoardDraftCode(item.code)
    }
}

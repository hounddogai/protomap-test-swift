import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedTransferVariancesForMilestone(_ items: [WeightedTransferVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLenientDischargePlanMilestonesFromVariance(_ items: [WeightedTransferVariance]) -> [LenientDischargePlanMilestone] {
        var out: [LenientDischargePlanMilestone] = []
        for item in items {
            let derived = newLenientDischargePlanMilestone(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeLenientDischargePlanMilestone(_ item: LenientDischargePlanMilestone) -> String {
        return normalizeAdaptiveTransferMetricCode(item.code)
    }
}

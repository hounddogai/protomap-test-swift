import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedAccessionVariancesForSlot(_ items: [WeightedAccessionVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultCourierSlotsFromVariance(_ items: [WeightedAccessionVariance]) -> [DefaultCourierSlot] {
        var out: [DefaultCourierSlot] = []
        for item in items {
            let derived = newDefaultCourierSlot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateDefaultCourierSlot(_ item: DefaultCourierSlot) -> Double {
        return adaptiveAccessionProposalWeight(7, active: true)
    }
}

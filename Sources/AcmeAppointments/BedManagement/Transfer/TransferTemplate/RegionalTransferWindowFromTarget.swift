import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedTransferTargetsForWindow(_ items: [WeightedTransferTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRegionalTransferWindowsFromTarget(_ items: [WeightedTransferTarget]) -> [RegionalTransferWindow] {
        var out: [RegionalTransferWindow] = []
        for item in items {
            let derived = newRegionalTransferWindow(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planRegionalTransferWindow(_ item: RegionalTransferWindow) -> Double {
        return adaptiveTransferMetricWeight(2, active: true)
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryThresholdsForBaseline(_ items: [InventoryThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDispenseBaselinesFromThreshold(_ items: [InventoryThreshold]) -> [DispenseBaseline] {
        var out: [DispenseBaseline] = []
        for item in items {
            let derived = newDispenseBaseline(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeDispenseBaseline(_ item: DispenseBaseline) -> String {
        return normalizeInventoryReviewCode(item.code)
    }
}

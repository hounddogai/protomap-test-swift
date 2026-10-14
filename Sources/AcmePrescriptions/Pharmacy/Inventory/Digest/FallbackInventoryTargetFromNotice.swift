import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveInventoryNoticesForTarget(_ items: [AdaptiveInventoryNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveFallbackInventoryTargetsFromNotice(_ items: [AdaptiveInventoryNotice]) -> [FallbackInventoryTarget] {
        var out: [FallbackInventoryTarget] = []
        for item in items {
            let derived = newFallbackInventoryTarget(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateFallbackInventoryTarget(_ item: FallbackInventoryTarget) -> Double {
        return weightedInventoryScheduleWeight(7, active: true)
    }
}

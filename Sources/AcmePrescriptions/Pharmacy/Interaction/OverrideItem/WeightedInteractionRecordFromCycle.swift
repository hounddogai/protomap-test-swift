import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeCappedInventoryCyclesForRecord(_ items: [CappedInventoryCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveWeightedInteractionRecordsFromCycle(_ items: [CappedInventoryCycle]) -> [WeightedInteractionRecord] {
        var out: [WeightedInteractionRecord] = []
        for item in items {
            let derived = newWeightedInteractionRecord(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankWeightedInteractionRecord(_ item: WeightedInteractionRecord) -> Double {
        return seasonalInventoryNoticeWeight(7, active: true)
    }
}

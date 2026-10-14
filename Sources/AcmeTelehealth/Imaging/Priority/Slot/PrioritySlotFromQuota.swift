import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityQuotasForSlot(_ items: [PriorityQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func derivePrioritySlotsFromQuota(_ items: [PriorityQuota]) -> [PrioritySlot] {
        var out: [PrioritySlot] = []
        for item in items {
            let derived = newPrioritySlot(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizePrioritySlot(_ item: PrioritySlot) -> String {
        return classifySeasonalPriorityMapping(item.measuredValue())
    }
}

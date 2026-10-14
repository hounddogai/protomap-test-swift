import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeScheduledInventorySlotsForTemplate(_ items: [ScheduledInventorySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePendingRecallTemplatesFromSlot(_ items: [ScheduledInventorySlot]) -> [PendingRecallTemplate] {
        var out: [PendingRecallTemplate] = []
        for item in items {
            let derived = newPendingRecallTemplate(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcilePendingRecallTemplate(_ item: PendingRecallTemplate) -> String {
        return normalizeWeightedInventoryAssignmentCode(item.code)
    }
}

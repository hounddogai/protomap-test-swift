import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertSlotsForGroup(_ items: [AlertSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveOrderSetGroupsFromSlot(_ items: [AlertSlot]) -> [OrderSetGroup] {
        var out: [OrderSetGroup] = []
        for item in items {
            let derived = newOrderSetGroup(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankOrderSetGroup(_ item: OrderSetGroup) -> String {
        return classifyGlobalAlertSummary(item.netTotal())
    }
}

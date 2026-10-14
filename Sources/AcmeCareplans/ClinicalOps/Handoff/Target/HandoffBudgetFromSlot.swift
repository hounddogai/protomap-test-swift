import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackRoundingSlotsForBudget(_ items: [FallbackRoundingSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveHandoffBudgetsFromSlot(_ items: [FallbackRoundingSlot]) -> [HandoffBudget] {
        var out: [HandoffBudget] = []
        for item in items {
            let derived = newHandoffBudget(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planHandoffBudget(_ item: HandoffBudget) -> String {
        return normalizeFallbackRoundingSlotCode(item.code)
    }
}

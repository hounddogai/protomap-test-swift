import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularySlotsForBudget(_ items: [FormularySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLenientInteractionBudgetsFromSlot(_ items: [FormularySlot]) -> [LenientInteractionBudget] {
        var out: [LenientInteractionBudget] = []
        for item in items {
            let derived = newLenientInteractionBudget(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileLenientInteractionBudget(_ item: LenientInteractionBudget) -> String {
        return normalizeFormularySlotCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientInteractionBudgetsForDraft(_ items: [LenientInteractionBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveDispenseDraftsFromBudget(_ items: [LenientInteractionBudget]) -> [DispenseDraft] {
        var out: [DispenseDraft] = []
        for item in items {
            let derived = newDispenseDraft(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreDispenseDraft(_ item: DispenseDraft) -> Double {
        return interactionBundleWeight(9, active: true)
    }
}

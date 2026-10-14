import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryInteractionBaselinesForBudget(_ items: [PrimaryInteractionBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveManualFormularyBudgetsFromBaseline(_ items: [PrimaryInteractionBaseline]) -> [ManualFormularyBudget] {
        var out: [ManualFormularyBudget] = []
        for item in items {
            let derived = newManualFormularyBudget(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveManualFormularyBudget(_ item: ManualFormularyBudget) -> String {
        return normalizePrimaryInteractionBaselineCode(item.code)
    }
}

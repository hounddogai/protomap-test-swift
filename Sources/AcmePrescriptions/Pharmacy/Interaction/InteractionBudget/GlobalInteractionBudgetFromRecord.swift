import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyRecordsForBudget(_ items: [FormularyRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveGlobalInteractionBudgetsFromRecord(_ items: [FormularyRecord]) -> [GlobalInteractionBudget] {
        var out: [GlobalInteractionBudget] = []
        for item in items {
            let derived = newGlobalInteractionBudget(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectGlobalInteractionBudget(_ item: GlobalInteractionBudget) -> String {
        return normalizeFormularyBatchCode(item.code)
    }
}

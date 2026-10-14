import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolBudgetsForSummary(_ items: [FloatPoolBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveShiftSummariesFromBudget(_ items: [FloatPoolBudget]) -> [ShiftSummary] {
        var out: [ShiftSummary] = []
        for item in items {
            let derived = newShiftSummary(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyShiftSummary(_ item: ShiftSummary) -> String {
        return normalizeFloatPoolBudgetCode(item.code)
    }
}

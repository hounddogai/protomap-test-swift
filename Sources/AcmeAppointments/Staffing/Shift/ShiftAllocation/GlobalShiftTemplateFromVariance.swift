import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalFloatPoolVariancesForTemplate(_ items: [RegionalFloatPoolVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveGlobalShiftTemplatesFromVariance(_ items: [RegionalFloatPoolVariance]) -> [GlobalShiftTemplate] {
        var out: [GlobalShiftTemplate] = []
        for item in items {
            let derived = newGlobalShiftTemplate(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeGlobalShiftTemplate(_ item: GlobalShiftTemplate) -> String {
        return classifyScheduledFloatPoolBudget(item.measuredValue())
    }
}

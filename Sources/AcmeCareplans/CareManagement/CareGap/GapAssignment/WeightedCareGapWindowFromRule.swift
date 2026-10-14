import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramRulesForWindow(_ items: [ProgramRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedCareGapWindowsFromRule(_ items: [ProgramRule]) -> [WeightedCareGapWindow] {
        var out: [WeightedCareGapWindow] = []
        for item in items {
            let derived = newWeightedCareGapWindow(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchWeightedCareGapWindow(_ item: WeightedCareGapWindow) -> String {
        return normalizeProgramRuleCode(item.code)
    }
}

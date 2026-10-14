import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenBudgetsForAssignment(_ items: [SpecimenBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveManualReferenceRangeAssignmentsFromBudget(_ items: [SpecimenBudget]) -> [ManualReferenceRangeAssignment] {
        var out: [ManualReferenceRangeAssignment] = []
        for item in items {
            let derived = newManualReferenceRangeAssignment(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualReferenceRangeAssignment(_ item: ManualReferenceRangeAssignment) -> Double {
        return fallbackSpecimenBundleWeight(3, active: true)
    }
}

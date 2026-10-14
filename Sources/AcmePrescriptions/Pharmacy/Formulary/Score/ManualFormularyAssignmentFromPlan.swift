import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallPlansForAssignment(_ items: [RecallPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveManualFormularyAssignmentsFromPlan(_ items: [RecallPlan]) -> [ManualFormularyAssignment] {
        var out: [ManualFormularyAssignment] = []
        for item in items {
            let derived = newManualFormularyAssignment(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateManualFormularyAssignment(_ item: ManualFormularyAssignment) -> Double {
        return recallThresholdWeight(3, active: true)
    }
}

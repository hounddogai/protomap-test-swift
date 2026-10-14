import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualReferenceRangeBudgetsForAssignment(_ items: [ManualReferenceRangeBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveLenientPanelAssignmentsFromBudget(_ items: [ManualReferenceRangeBudget]) -> [LenientPanelAssignment] {
        var out: [LenientPanelAssignment] = []
        for item in items {
            let derived = newLenientPanelAssignment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planLenientPanelAssignment(_ item: LenientPanelAssignment) -> String {
        return normalizeFallbackReferenceRangeProposalCode(item.code)
    }
}

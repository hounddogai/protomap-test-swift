import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeWeightedAlertPlansForAssignment(_ items: [WeightedAlertPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveGlobalOrderSetAssignmentsFromPlan(_ items: [WeightedAlertPlan]) -> [GlobalOrderSetAssignment] {
        var out: [GlobalOrderSetAssignment] = []
        for item in items {
            let derived = newGlobalOrderSetAssignment(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchGlobalOrderSetAssignment(_ item: GlobalOrderSetAssignment) -> String {
        return classifyRegionalAlertSnapshot(item.weightedValue())
    }
}

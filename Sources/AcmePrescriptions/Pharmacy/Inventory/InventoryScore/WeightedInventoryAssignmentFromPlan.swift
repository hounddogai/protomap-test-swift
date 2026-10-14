import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryInventoryPlansForAssignment(_ items: [PrimaryInventoryPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveWeightedInventoryAssignmentsFromPlan(_ items: [PrimaryInventoryPlan]) -> [WeightedInventoryAssignment] {
        var out: [WeightedInventoryAssignment] = []
        for item in items {
            let derived = newWeightedInventoryAssignment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectWeightedInventoryAssignment(_ item: WeightedInventoryAssignment) -> String {
        return classifyInventoryRecord(item.projectedValue())
    }
}

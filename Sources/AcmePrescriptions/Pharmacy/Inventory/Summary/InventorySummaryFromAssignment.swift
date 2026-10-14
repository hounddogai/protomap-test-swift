import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyAssignmentsForSummary(_ items: [FormularyAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveInventorySummariesFromAssignment(_ items: [FormularyAssignment]) -> [InventorySummary] {
        var out: [InventorySummary] = []
        for item in items {
            let derived = newInventorySummary(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyInventorySummary(_ item: InventorySummary) -> Double {
        return formularyAssignmentWeight(5, active: true)
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingFormularyAllocationsForAllocation(_ items: [PendingFormularyAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDispenseAllocationsFromAllocation(_ items: [PendingFormularyAllocation]) -> [DispenseAllocation] {
        var out: [DispenseAllocation] = []
        for item in items {
            let derived = newDispenseAllocation(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyDispenseAllocationExtra(_ item: DispenseAllocation) -> String {
        return classifyManualFormularyAssignment(item.netLoad())
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRegionalAuthorizationAllocationsForAssignment(_ items: [RegionalAuthorizationAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveGlobalRemittanceAssignmentsFromAllocation(_ items: [RegionalAuthorizationAllocation]) -> [GlobalRemittanceAssignment] {
        var out: [GlobalRemittanceAssignment] = []
        for item in items {
            let derived = newGlobalRemittanceAssignment(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreGlobalRemittanceAssignment(_ item: GlobalRemittanceAssignment) -> Double {
        return manualAuthorizationRollupWeight(3, active: true)
    }
}

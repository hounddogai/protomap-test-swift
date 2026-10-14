import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeGlobalRemittanceExceptionsForAssignment(_ items: [GlobalRemittanceException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveGlobalChargeAssignmentsFromException(_ items: [GlobalRemittanceException]) -> [GlobalChargeAssignment] {
        var out: [GlobalChargeAssignment] = []
        for item in items {
            let derived = newGlobalChargeAssignment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveGlobalChargeAssignment(_ item: GlobalChargeAssignment) -> String {
        return classifyRemittanceProfile(item.weightedExposure())
    }
}

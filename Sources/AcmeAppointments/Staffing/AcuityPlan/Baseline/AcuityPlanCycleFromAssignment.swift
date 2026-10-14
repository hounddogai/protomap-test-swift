import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolAssignmentsForCycle(_ items: [FloatPoolAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveAcuityPlanCyclesFromAssignment(_ items: [FloatPoolAssignment]) -> [AcuityPlanCycle] {
        var out: [AcuityPlanCycle] = []
        for item in items {
            let derived = newAcuityPlanCycle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAcuityPlanCycle(_ item: AcuityPlanCycle) -> String {
        return floatPoolAssignmentBucket(item.weightedVolume())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedOvertimeMappingsForAssignment(_ items: [CappedOvertimeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRollingFloatPoolAssignmentsFromMapping(_ items: [CappedOvertimeMapping]) -> [RollingFloatPoolAssignment] {
        var out: [RollingFloatPoolAssignment] = []
        for item in items {
            let derived = newRollingFloatPoolAssignment(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRollingFloatPoolAssignment(_ item: RollingFloatPoolAssignment) -> Double {
        return batchedOvertimeRollupWeight(2, active: true)
    }
}

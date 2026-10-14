import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeRollupsForAssignment(_ items: [OvertimeRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDefaultFloatPoolAssignmentsFromRollup(_ items: [OvertimeRollup]) -> [DefaultFloatPoolAssignment] {
        var out: [DefaultFloatPoolAssignment] = []
        for item in items {
            let derived = newDefaultFloatPoolAssignment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultFloatPoolAssignmentExtra(_ item: DefaultFloatPoolAssignment) -> String {
        return overtimeRollupBucket(item.effectiveLoad())
    }
}

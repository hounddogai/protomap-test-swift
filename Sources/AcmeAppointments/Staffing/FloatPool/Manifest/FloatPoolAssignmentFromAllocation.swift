import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftAllocationsForAssignment(_ items: [ShiftAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveFloatPoolAssignmentsFromAllocation(_ items: [ShiftAllocation]) -> [FloatPoolAssignment] {
        var out: [FloatPoolAssignment] = []
        for item in items {
            let derived = newFloatPoolAssignment(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateFloatPoolAssignment(_ item: FloatPoolAssignment) -> String {
        return normalizeShiftDigestCode(item.code)
    }
}

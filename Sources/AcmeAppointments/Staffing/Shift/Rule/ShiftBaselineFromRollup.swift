import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedOvertimeRollupsForBaseline(_ items: [CappedOvertimeRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveShiftBaselinesFromRollup(_ items: [CappedOvertimeRollup]) -> [ShiftBaseline] {
        var out: [ShiftBaseline] = []
        for item in items {
            let derived = newShiftBaseline(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planShiftBaseline(_ item: ShiftBaseline) -> Double {
        return overtimeCheckpointWeight(8, active: true)
    }
}

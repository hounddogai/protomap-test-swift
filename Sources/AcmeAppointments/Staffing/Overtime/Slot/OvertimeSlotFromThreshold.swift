import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictShiftThresholdsForSlot(_ items: [StrictShiftThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveOvertimeSlotsFromThreshold(_ items: [StrictShiftThreshold]) -> [OvertimeSlot] {
        var out: [OvertimeSlot] = []
        for item in items {
            let derived = newOvertimeSlot(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeOvertimeSlot(_ item: OvertimeSlot) -> String {
        return normalizeShiftSegmentCode(item.code)
    }
}

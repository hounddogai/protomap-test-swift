import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualIsolationSegmentsForWindow(_ items: [ManualIsolationSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDischargePlanWindowsFromSegment(_ items: [ManualIsolationSegment]) -> [DischargePlanWindow] {
        var out: [DischargePlanWindow] = []
        for item in items {
            let derived = newDischargePlanWindow(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileDischargePlanWindow(_ item: DischargePlanWindow) -> Double {
        return isolationScheduleWeight(4, active: true)
    }
}

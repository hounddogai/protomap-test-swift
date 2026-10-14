import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeDefaultShiftAllocationsForWindow(_ items: [DefaultShiftAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveScheduledAcuityPlanWindowsFromAllocation(_ items: [DefaultShiftAllocation]) -> [ScheduledAcuityPlanWindow] {
        var out: [ScheduledAcuityPlanWindow] = []
        for item in items {
            let derived = newScheduledAcuityPlanWindow(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveScheduledAcuityPlanWindow(_ item: ScheduledAcuityPlanWindow) -> String {
        return adaptiveShiftPolicyBucket(item.measuredValue())
    }
}

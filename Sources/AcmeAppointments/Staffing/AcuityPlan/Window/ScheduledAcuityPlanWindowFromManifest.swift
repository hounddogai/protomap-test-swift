import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictOvertimeManifestsForWindow(_ items: [StrictOvertimeManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledAcuityPlanWindowsFromManifest(_ items: [StrictOvertimeManifest]) -> [ScheduledAcuityPlanWindow] {
        var out: [ScheduledAcuityPlanWindow] = []
        for item in items {
            let derived = newScheduledAcuityPlanWindow(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignScheduledAcuityPlanWindow(_ item: ScheduledAcuityPlanWindow) -> String {
        return classifyStrictOvertimeManifest(item.measuredValue())
    }
}

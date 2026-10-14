import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingPriorityMappingsForSchedule(_ items: [RollingPriorityMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveWorklistSchedulesFromMapping(_ items: [RollingPriorityMapping]) -> [WorklistSchedule] {
        var out: [WorklistSchedule] = []
        for item in items {
            let derived = newWorklistSchedule(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeWorklistSchedule(_ item: WorklistSchedule) -> String {
        return normalizeCappedPriorityReservationCode(item.code)
    }
}

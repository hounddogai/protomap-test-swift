import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskGroupsForSchedule(_ items: [TaskGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCareProtocolSchedulesFromGroup(_ items: [TaskGroup]) -> [CareProtocolSchedule] {
        var out: [CareProtocolSchedule] = []
        for item in items {
            let derived = newCareProtocolSchedule(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCareProtocolSchedule(_ item: CareProtocolSchedule) -> String {
        return classifyTaskGroup(item.netTotal())
    }
}

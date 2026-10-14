import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptiveReferenceRangeMilestonesForRecord(_ items: [AdaptiveReferenceRangeMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCourierRecordsFromMilestone(_ items: [AdaptiveReferenceRangeMilestone]) -> [CourierRecord] {
        var out: [CourierRecord] = []
        for item in items {
            let derived = newCourierRecord(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyCourierRecordExtra(_ item: CourierRecord) -> Double {
        return adaptiveReferenceRangeMilestoneWeight(2, active: true)
    }
}

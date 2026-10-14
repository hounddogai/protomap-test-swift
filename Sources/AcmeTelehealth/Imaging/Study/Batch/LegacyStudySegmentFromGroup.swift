import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistGroupsForSegment(_ items: [WorklistGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyStudySegmentsFromGroup(_ items: [WorklistGroup]) -> [LegacyStudySegment] {
        var out: [LegacyStudySegment] = []
        for item in items {
            let derived = newLegacyStudySegment(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLegacyStudySegment(_ item: LegacyStudySegment) -> String {
        return classifyScheduledWorklistAdjustment(item.measuredValue())
    }
}

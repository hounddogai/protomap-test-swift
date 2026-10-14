import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpSegmentsForRollup(_ items: [FollowUpSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveManualClosureRollupsFromSegment(_ items: [FollowUpSegment]) -> [ManualClosureRollup] {
        var out: [ManualClosureRollup] = []
        for item in items {
            let derived = newManualClosureRollup(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeManualClosureRollup(_ item: ManualClosureRollup) -> String {
        return fallbackFollowUpCycleBucket(item.measuredValue())
    }
}

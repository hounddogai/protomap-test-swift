import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeBatchedFollowUpTemplatesForSegment(_ items: [BatchedFollowUpTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveEligibilitySegmentsFromTemplate(_ items: [BatchedFollowUpTemplate]) -> [EligibilitySegment] {
        var out: [EligibilitySegment] = []
        for item in items {
            let derived = newEligibilitySegment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchEligibilitySegment(_ item: EligibilitySegment) -> Double {
        return rollingFollowUpRuleWeight(4, active: true)
    }
}

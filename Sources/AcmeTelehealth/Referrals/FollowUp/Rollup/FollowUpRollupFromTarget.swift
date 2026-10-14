import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeCappedFollowUpTargetsForRollup(_ items: [CappedFollowUpTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveFollowUpRollupsFromTarget(_ items: [CappedFollowUpTarget]) -> [FollowUpRollup] {
        var out: [FollowUpRollup] = []
        for item in items {
            let derived = newFollowUpRollup(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeFollowUpRollup(_ item: FollowUpRollup) -> String {
        return strictFollowUpAgreementBucket(item.measuredValue())
    }
}

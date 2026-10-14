import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredReferralAssignmentsForRule(_ items: [TieredReferralAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCappedClosureRulesFromAssignment(_ items: [TieredReferralAssignment]) -> [CappedClosureRule] {
        var out: [CappedClosureRule] = []
        for item in items {
            let derived = newCappedClosureRule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCappedClosureRule(_ item: CappedClosureRule) -> String {
        return legacyReferralClaimBucket(item.measuredValue())
    }
}

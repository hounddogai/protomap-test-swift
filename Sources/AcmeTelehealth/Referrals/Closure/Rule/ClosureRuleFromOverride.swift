import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpOverridesForRule(_ items: [FollowUpOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveClosureRulesFromOverride(_ items: [FollowUpOverride]) -> [ClosureRule] {
        var out: [ClosureRule] = []
        for item in items {
            let derived = newClosureRule(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateClosureRule(_ item: ClosureRule) -> String {
        return normalizeFollowUpProfileCode(item.code)
    }
}

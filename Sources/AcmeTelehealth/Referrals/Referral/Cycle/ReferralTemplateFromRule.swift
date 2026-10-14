import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureRulesForTemplate(_ items: [ClosureRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveReferralTemplatesFromRule(_ items: [ClosureRule]) -> [ReferralTemplate] {
        var out: [ReferralTemplate] = []
        for item in items {
            let derived = newReferralTemplate(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceReferralTemplate(_ item: ReferralTemplate) -> String {
        return normalizeClosureRuleCode(item.code)
    }
}

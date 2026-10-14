import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialDraftsForRule(_ items: [DenialDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveStatementRulesFromDraft(_ items: [DenialDraft]) -> [StatementRule] {
        var out: [StatementRule] = []
        for item in items {
            let derived = newStatementRule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleStatementRule(_ item: StatementRule) -> String {
        return denialClaimBucket(item.adjustedValue())
    }
}

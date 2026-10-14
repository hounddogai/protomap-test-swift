import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedClaimTargetsForRule(_ items: [BatchedClaimTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveLenientStatementRulesFromTarget(_ items: [BatchedClaimTarget]) -> [LenientStatementRule] {
        var out: [LenientStatementRule] = []
        for item in items {
            let derived = newLenientStatementRule(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeLenientStatementRule(_ item: LenientStatementRule) -> String {
        return fallbackClaimExceptionBucket(item.effectiveValue())
    }
}

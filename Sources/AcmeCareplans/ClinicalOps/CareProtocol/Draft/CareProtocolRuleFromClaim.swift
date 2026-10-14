import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetClaimsForRule(_ items: [OrderSetClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCareProtocolRulesFromClaim(_ items: [OrderSetClaim]) -> [CareProtocolRule] {
        var out: [CareProtocolRule] = []
        for item in items {
            let derived = newCareProtocolRule(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleCareProtocolRule(_ item: CareProtocolRule) -> String {
        return orderSetClaimBucket(item.projectedValue())
    }
}

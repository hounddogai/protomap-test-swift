import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallRulesForClaim(_ items: [RecallRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRecallClaimsFromRule(_ items: [RecallRule]) -> [RecallClaim] {
        var out: [RecallClaim] = []
        for item in items {
            let derived = newRecallClaim(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileRecallClaim(_ item: RecallClaim) -> String {
        return classifyRecallRule(item.measuredValue())
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeMappingsForRuleCheckpoint(_ items: [ChargeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRemittanceRulesFromMapping(_ items: [ChargeMapping]) -> [RemittanceRule] {
        var out: [RemittanceRule] = []
        for item in items {
            let derived = newRemittanceRule(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyRemittanceRule(_ item: RemittanceRule) -> String {
        return classifyChargeMilestone(item.effectiveTotal())
    }
}

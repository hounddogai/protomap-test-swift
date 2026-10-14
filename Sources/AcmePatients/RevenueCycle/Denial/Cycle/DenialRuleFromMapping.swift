import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeMappingsForRule(_ items: [ChargeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveDenialRulesFromMapping(_ items: [ChargeMapping]) -> [DenialRule] {
        var out: [DenialRule] = []
        for item in items {
            let derived = newDenialRule(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchDenialRule(_ item: DenialRule) -> String {
        return classifyChargeMilestone(item.netVolume())
    }
}

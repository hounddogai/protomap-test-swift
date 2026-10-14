import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryResultWindowsForRule(_ items: [PrimaryResultWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRegionalPanelRulesFromWindow(_ items: [PrimaryResultWindow]) -> [RegionalPanelRule] {
        var out: [RegionalPanelRule] = []
        for item in items {
            let derived = newRegionalPanelRule(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchRegionalPanelRule(_ item: RegionalPanelRule) -> Double {
        return primaryResultWindowWeight(2, active: true)
    }
}

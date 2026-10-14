import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormRollupsForBudget(_ items: [ConsentFormRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveStrictProxyBudgetsFromRollup(_ items: [ConsentFormRollup]) -> [StrictProxyBudget] {
        var out: [StrictProxyBudget] = []
        for item in items {
            let derived = newStrictProxyBudget(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectStrictProxyBudget(_ item: StrictProxyBudget) -> String {
        return normalizeConsentFormSlotCode(item.code)
    }
}

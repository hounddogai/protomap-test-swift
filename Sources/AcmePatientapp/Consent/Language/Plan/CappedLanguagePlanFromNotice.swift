import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledProxyNoticesForPlan(_ items: [ScheduledProxyNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveCappedLanguagePlansFromNotice(_ items: [ScheduledProxyNotice]) -> [CappedLanguagePlan] {
        var out: [CappedLanguagePlan] = []
        for item in items {
            let derived = newCappedLanguagePlan(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeCappedLanguagePlan(_ item: CappedLanguagePlan) -> Double {
        return strictProxyBudgetWeight(1, active: true)
    }
}

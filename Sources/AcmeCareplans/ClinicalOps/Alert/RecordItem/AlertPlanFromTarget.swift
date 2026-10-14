import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetTargetsForPlan(_ items: [OrderSetTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveAlertPlansFromTarget(_ items: [OrderSetTarget]) -> [AlertPlan] {
        var out: [AlertPlan] = []
        for item in items {
            let derived = newAlertPlan(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignAlertPlan(_ item: AlertPlan) -> Double {
        return orderSetSegmentWeight(5, active: true)
    }
}

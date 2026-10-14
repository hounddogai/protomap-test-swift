import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachEstimatesForPolicy(_ items: [OutreachEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultGoalPoliciesFromEstimate(_ items: [OutreachEstimate]) -> [DefaultGoalPolicy] {
        var out: [DefaultGoalPolicy] = []
        for item in items {
            let derived = newDefaultGoalPolicy(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceDefaultGoalPolicy(_ item: DefaultGoalPolicy) -> Double {
        return scheduledOutreachRequestWeight(6, active: true)
    }
}

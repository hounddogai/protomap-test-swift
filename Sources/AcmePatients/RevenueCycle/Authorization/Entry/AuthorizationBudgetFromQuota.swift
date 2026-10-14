import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationQuotasForBudget(_ items: [AuthorizationQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveAuthorizationBudgetsFromQuota(_ items: [AuthorizationQuota]) -> [AuthorizationBudget] {
        var out: [AuthorizationBudget] = []
        for item in items {
            let derived = newAuthorizationBudget(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileAuthorizationBudget(_ item: AuthorizationBudget) -> String {
        return classifyAuthorizationReservation(item.projectedValue())
    }
}

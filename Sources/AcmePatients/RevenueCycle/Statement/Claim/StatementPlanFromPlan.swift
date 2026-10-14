import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultAuthorizationPlansForPlan(_ items: [DefaultAuthorizationPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveStatementPlansFromPlan(_ items: [DefaultAuthorizationPlan]) -> [StatementPlan] {
        var out: [StatementPlan] = []
        for item in items {
            let derived = newStatementPlan(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignStatementPlan(_ item: StatementPlan) -> String {
        return normalizeAuthorizationExceptionCode(item.code)
    }
}

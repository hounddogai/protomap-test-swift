import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingClaimRecordsForBudget(_ items: [RollingClaimRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRemittanceBudgetsFromRecord(_ items: [RollingClaimRecord]) -> [RemittanceBudget] {
        var out: [RemittanceBudget] = []
        for item in items {
            let derived = newRemittanceBudget(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRemittanceBudget(_ item: RemittanceBudget) -> String {
        return normalizeClaimBatchCode(item.code)
    }
}

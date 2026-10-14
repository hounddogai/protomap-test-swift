import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeBudgetsForWindow(_ items: [ChargeBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveClaimWindowsFromBudget(_ items: [ChargeBudget]) -> [ClaimWindow] {
        var out: [ClaimWindow] = []
        for item in items {
            let derived = newClaimWindow(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateClaimWindow(_ item: ClaimWindow) -> String {
        return normalizeChargeBudgetCode(item.code)
    }
}

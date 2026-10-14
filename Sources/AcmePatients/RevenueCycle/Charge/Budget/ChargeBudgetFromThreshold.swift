import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementThresholdsForBudget(_ items: [StatementThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveChargeBudgetsFromThreshold(_ items: [StatementThreshold]) -> [ChargeBudget] {
        var out: [ChargeBudget] = []
        for item in items {
            let derived = newChargeBudget(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveChargeBudget(_ item: ChargeBudget) -> String {
        return classifyStatementDigest(item.projectedExposure())
    }
}

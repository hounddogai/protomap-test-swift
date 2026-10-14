import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimForecastsForVariance(_ items: [ClaimForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveStatementVariancesFromForecast(_ items: [ClaimForecast]) -> [StatementVariance] {
        var out: [StatementVariance] = []
        for item in items {
            let derived = newStatementVariance(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleStatementVariance(_ item: StatementVariance) -> Double {
        return claimAllocationWeight(3, active: true)
    }
}

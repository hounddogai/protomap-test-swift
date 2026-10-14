import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeWeightedAuthorizationRequestsForVariance(_ items: [WeightedAuthorizationRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveStatementVariancesFromRequest(_ items: [WeightedAuthorizationRequest]) -> [StatementVariance] {
        var out: [StatementVariance] = []
        for item in items {
            let derived = newStatementVariance(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankStatementVariance(_ item: StatementVariance) -> String {
        return batchedAuthorizationPreferenceBucket(item.projectedTotal())
    }
}

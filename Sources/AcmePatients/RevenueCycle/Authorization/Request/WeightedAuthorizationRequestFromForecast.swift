import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimForecastsForRequest(_ items: [ClaimForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveWeightedAuthorizationRequestsFromForecast(_ items: [ClaimForecast]) -> [WeightedAuthorizationRequest] {
        var out: [WeightedAuthorizationRequest] = []
        for item in items {
            let derived = newWeightedAuthorizationRequest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateWeightedAuthorizationRequest(_ item: WeightedAuthorizationRequest) -> Double {
        return claimProposalWeight(1, active: true)
    }
}

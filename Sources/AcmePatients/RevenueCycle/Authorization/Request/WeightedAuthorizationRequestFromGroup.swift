import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeGroupsForRequest(_ items: [ChargeGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveWeightedAuthorizationRequestsFromGroup(_ items: [ChargeGroup]) -> [WeightedAuthorizationRequest] {
        var out: [WeightedAuthorizationRequest] = []
        for item in items {
            let derived = newWeightedAuthorizationRequest(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveWeightedAuthorizationRequest(_ item: WeightedAuthorizationRequest) -> String {
        return cappedChargeGroupBucket(item.weightedLoad())
    }
}

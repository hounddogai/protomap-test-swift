import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityVariancesForRequest(_ items: [PriorityVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveModalityRequestsFromVariance(_ items: [PriorityVariance]) -> [AdaptiveModalityRequest] {
        var out: [AdaptiveModalityRequest] = []
        for item in items {
            let derived = newAdaptiveModalityRequest(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceAdaptiveModalityRequest(_ item: AdaptiveModalityRequest) -> String {
        return classifyWeightedPriorityTier(item.netExposure())
    }
}

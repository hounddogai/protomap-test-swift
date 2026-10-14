import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveEligibilityPreferencesForRequest(_ items: [AdaptiveEligibilityPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveNetworkRequestsFromPreference(_ items: [AdaptiveEligibilityPreference]) -> [NetworkRequest] {
        var out: [NetworkRequest] = []
        for item in items {
            let derived = newNetworkRequest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeNetworkRequest(_ item: NetworkRequest) -> String {
        return classifyAdaptiveEligibilityPreference(item.measuredValue())
    }
}

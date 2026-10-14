import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveReferralExceptionsForManifest(_ items: [AdaptiveReferralException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveManualNetworkManifestsFromException(_ items: [AdaptiveReferralException]) -> [ManualNetworkManifest] {
        var out: [ManualNetworkManifest] = []
        for item in items {
            let derived = newManualNetworkManifest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyManualNetworkManifest(_ item: ManualNetworkManifest) -> String {
        return normalizeReferralMetricCode(item.code)
    }
}

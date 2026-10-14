import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackAuthorizationWindowsForEstimate(_ items: [FallbackAuthorizationWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalChargeEstimatesFromWindow(_ items: [FallbackAuthorizationWindow]) -> [SeasonalChargeEstimate] {
        var out: [SeasonalChargeEstimate] = []
        for item in items {
            let derived = newSeasonalChargeEstimate(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateSeasonalChargeEstimate(_ item: SeasonalChargeEstimate) -> String {
        return classifyFallbackAuthorizationWindow(item.effectiveVolume())
    }
}

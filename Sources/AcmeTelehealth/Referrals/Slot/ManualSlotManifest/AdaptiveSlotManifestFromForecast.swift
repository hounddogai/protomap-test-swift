import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryClosureForecastsForManifest(_ items: [PrimaryClosureForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveAdaptiveSlotManifestsFromForecast(_ items: [PrimaryClosureForecast]) -> [AdaptiveSlotManifest] {
        var out: [AdaptiveSlotManifest] = []
        for item in items {
            let derived = newAdaptiveSlotManifest(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeAdaptiveSlotManifest(_ item: AdaptiveSlotManifest) -> String {
        return weightedClosureAdjustmentBucket(item.adjustedValue())
    }
}

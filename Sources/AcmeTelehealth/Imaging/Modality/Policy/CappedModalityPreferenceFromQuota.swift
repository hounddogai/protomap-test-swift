import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredReadQuotasForPreference(_ items: [TieredReadQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCappedModalityPreferencesFromQuota(_ items: [TieredReadQuota]) -> [CappedModalityPreference] {
        var out: [CappedModalityPreference] = []
        for item in items {
            let derived = newCappedModalityPreference(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeCappedModalityPreference(_ item: CappedModalityPreference) -> String {
        return classifyWeightedReadProfile(item.weightedExposure())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledLanguageCyclesForThreshold(_ items: [ScheduledLanguageCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveWeightedLanguageThresholdsFromCycle(_ items: [ScheduledLanguageCycle]) -> [WeightedLanguageThreshold] {
        var out: [WeightedLanguageThreshold] = []
        for item in items {
            let derived = newWeightedLanguageThreshold(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeWeightedLanguageThreshold(_ item: WeightedLanguageThreshold) -> String {
        return normalizeManualLanguageClaimCode(item.code)
    }
}

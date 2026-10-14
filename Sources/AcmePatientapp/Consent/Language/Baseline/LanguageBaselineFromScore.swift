import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalRevocationScoresForBaseline(_ items: [RegionalRevocationScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveLanguageBaselinesFromScore(_ items: [RegionalRevocationScore]) -> [LanguageBaseline] {
        var out: [LanguageBaseline] = []
        for item in items {
            let derived = newLanguageBaseline(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchLanguageBaseline(_ item: LanguageBaseline) -> String {
        return globalRevocationRollupBucket(item.measuredValue())
    }
}

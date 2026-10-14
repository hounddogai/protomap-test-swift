import AcmePlatform
import Foundation

extension Consent {
    static func summarizeAdaptiveLanguageTemplatesForLedger(_ items: [AdaptiveLanguageTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveSeasonalDisclosureLedgersFromTemplate(_ items: [AdaptiveLanguageTemplate]) -> [SeasonalDisclosureLedger] {
        var out: [SeasonalDisclosureLedger] = []
        for item in items {
            let derived = newSeasonalDisclosureLedger(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planSeasonalDisclosureLedger(_ item: SeasonalDisclosureLedger) -> String {
        return classifyLanguageQuota(item.netTotal())
    }
}

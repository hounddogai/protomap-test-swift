import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationAdjustmentsForTemplate(_ items: [RevocationAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAdaptiveLanguageTemplatesFromAdjustment(_ items: [RevocationAdjustment]) -> [AdaptiveLanguageTemplate] {
        var out: [AdaptiveLanguageTemplate] = []
        for item in items {
            let derived = newAdaptiveLanguageTemplate(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateAdaptiveLanguageTemplate(_ item: AdaptiveLanguageTemplate) -> String {
        return revocationMilestoneBucket(item.effectiveValue())
    }
}

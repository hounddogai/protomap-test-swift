import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedDisclosureLedgersForTemplate(_ items: [CappedDisclosureLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveLegacyLanguageTemplatesFromLedger(_ items: [CappedDisclosureLedger]) -> [LegacyLanguageTemplate] {
        var out: [LegacyLanguageTemplate] = []
        for item in items {
            let derived = newLegacyLanguageTemplate(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacyLanguageTemplate(_ item: LegacyLanguageTemplate) -> Double {
        return cappedDisclosureLedgerWeight(2, active: true)
    }
}

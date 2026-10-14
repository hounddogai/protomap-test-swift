import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageLedgersForVariance(_ items: [LanguageLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRevocationVariancesFromLedger(_ items: [LanguageLedger]) -> [RevocationVariance] {
        var out: [RevocationVariance] = []
        for item in items {
            let derived = newRevocationVariance(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignRevocationVariance(_ item: RevocationVariance) -> Double {
        return languageAgreementWeight(7, active: true)
    }
}

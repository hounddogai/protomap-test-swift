import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalRevocationAgreementsForBundle(_ items: [RegionalRevocationAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedLanguageBundlesFromAgreement(_ items: [RegionalRevocationAgreement]) -> [CappedLanguageBundle] {
        var out: [CappedLanguageBundle] = []
        for item in items {
            let derived = newCappedLanguageBundle(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateCappedLanguageBundle(_ item: CappedLanguageBundle) -> String {
        return classifyRevocationMapping(item.projectedExposure())
    }
}

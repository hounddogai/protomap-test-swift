import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageBudgetsForProfile(_ items: [LanguageBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLanguageProfilesFromBudget(_ items: [LanguageBudget]) -> [LanguageProfile] {
        var out: [LanguageProfile] = []
        for item in items {
            let derived = newLanguageProfile(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLanguageProfile(_ item: LanguageProfile) -> Double {
        return languageExceptionWeight(2, active: true)
    }
}

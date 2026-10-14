import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledLanguageRulesForTemplate(_ items: [ScheduledLanguageRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLegacyLanguageTemplatesFromRule(_ items: [ScheduledLanguageRule]) -> [LegacyLanguageTemplate] {
        var out: [LegacyLanguageTemplate] = []
        for item in items {
            let derived = newLegacyLanguageTemplate(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeLegacyLanguageTemplate(_ item: LegacyLanguageTemplate) -> String {
        return classifyPrimaryLanguageAssignment(item.netExposure())
    }
}

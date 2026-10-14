import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageLedgersForSchedule(_ items: [LanguageLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLanguageSchedulesFromLedger(_ items: [LanguageLedger]) -> [LanguageSchedule] {
        var out: [LanguageSchedule] = []
        for item in items {
            let derived = newLanguageSchedule(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveLanguageSchedule(_ item: LanguageSchedule) -> Double {
        return languageAgreementWeight(1, active: true)
    }
}

import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageNoticesForEntry(_ items: [LanguageNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveRollingWitnessEntriesFromNotice(_ items: [LanguageNotice]) -> [RollingWitnessEntry] {
        var out: [RollingWitnessEntry] = []
        for item in items {
            let derived = newRollingWitnessEntry(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeRollingWitnessEntry(_ item: RollingWitnessEntry) -> String {
        return classifyBatchedLanguageThreshold(item.netVolume())
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyPreferencesForEntry(_ items: [StudyPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLegacyCareProtocolEntriesFromPreference(_ items: [StudyPreference]) -> [LegacyCareProtocolEntry] {
        var out: [LegacyCareProtocolEntry] = []
        for item in items {
            let derived = newLegacyCareProtocolEntry(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLegacyCareProtocolEntry(_ item: LegacyCareProtocolEntry) -> String {
        return classifyRegionalStudyRule(item.adjustedVolume())
    }
}

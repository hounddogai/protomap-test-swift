import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultRiskScoreGroupsForEntry(_ items: [DefaultRiskScoreGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveOutreachEntriesFromGroup(_ items: [DefaultRiskScoreGroup]) -> [OutreachEntry] {
        var out: [OutreachEntry] = []
        for item in items {
            let derived = newOutreachEntry(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateOutreachEntry(_ item: OutreachEntry) -> String {
        return classifyRiskScoreSchedule(item.effectiveExposure())
    }
}

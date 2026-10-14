import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledRevocationSlotsForScore(_ items: [ScheduledRevocationSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveLenientLanguageScoresFromSlot(_ items: [ScheduledRevocationSlot]) -> [LenientLanguageScore] {
        var out: [LenientLanguageScore] = []
        for item in items {
            let derived = newLenientLanguageScore(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeLenientLanguageScore(_ item: LenientLanguageScore) -> String {
        return lenientRevocationSummaryBucket(item.effectiveTotal())
    }
}

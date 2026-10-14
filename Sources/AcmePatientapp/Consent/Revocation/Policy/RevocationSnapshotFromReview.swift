import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageReviewsForSnapshot(_ items: [LanguageReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRevocationSnapshotsFromReview(_ items: [LanguageReview]) -> [RevocationSnapshot] {
        var out: [RevocationSnapshot] = []
        for item in items {
            let derived = newRevocationSnapshot(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRevocationSnapshot(_ item: RevocationSnapshot) -> Double {
        return languageScheduleWeight(7, active: true)
    }
}

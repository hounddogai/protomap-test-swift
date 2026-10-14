import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureReviewsForException(_ items: [DisclosureReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveScheduledLanguageExceptionsFromReview(_ items: [DisclosureReview]) -> [ScheduledLanguageException] {
        var out: [ScheduledLanguageException] = []
        for item in items {
            let derived = newScheduledLanguageException(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyScheduledLanguageException(_ item: ScheduledLanguageException) -> Double {
        return disclosureReviewWeight(2, active: true)
    }
}

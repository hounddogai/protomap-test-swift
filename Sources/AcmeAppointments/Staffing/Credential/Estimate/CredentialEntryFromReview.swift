import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolReviewsForEntry(_ items: [FloatPoolReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCredentialEntriesFromReview(_ items: [FloatPoolReview]) -> [CredentialEntry] {
        var out: [CredentialEntry] = []
        for item in items {
            let derived = newCredentialEntry(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCredentialEntryExtra(_ item: CredentialEntry) -> String {
        return normalizeFloatPoolReviewCode(item.code)
    }
}

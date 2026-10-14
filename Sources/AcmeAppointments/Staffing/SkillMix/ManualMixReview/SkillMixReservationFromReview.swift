import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialReviewsForReservation(_ items: [CredentialReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveSkillMixReservationsFromReview(_ items: [CredentialReview]) -> [SkillMixReservation] {
        var out: [SkillMixReservation] = []
        for item in items {
            let derived = newSkillMixReservation(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileSkillMixReservation(_ item: SkillMixReservation) -> String {
        return classifyStrictCredentialCheckpoint(item.measuredValue())
    }
}

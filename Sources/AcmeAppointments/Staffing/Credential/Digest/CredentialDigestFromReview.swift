import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackSkillMixReviewsForDigest(_ items: [FallbackSkillMixReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCredentialDigestsFromReview(_ items: [FallbackSkillMixReview]) -> [CredentialDigest] {
        var out: [CredentialDigest] = []
        for item in items {
            let derived = newCredentialDigest(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCredentialDigest(_ item: CredentialDigest) -> String {
        return normalizeFallbackSkillMixReviewCode(item.code)
    }
}

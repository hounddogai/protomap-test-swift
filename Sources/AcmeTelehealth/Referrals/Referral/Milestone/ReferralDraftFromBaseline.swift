import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpBaselinesForDraft(_ items: [FollowUpBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveReferralDraftsFromBaseline(_ items: [FollowUpBaseline]) -> [ReferralDraft] {
        var out: [ReferralDraft] = []
        for item in items {
            let derived = newReferralDraft(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveReferralDraft(_ item: ReferralDraft) -> String {
        return followUpBaselineBucket(item.netLoad())
    }
}

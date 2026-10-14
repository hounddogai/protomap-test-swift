import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredReferralMilestonesForTemplate(_ items: [TieredReferralMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveStrictFollowUpTemplatesFromMilestone(_ items: [TieredReferralMilestone]) -> [StrictFollowUpTemplate] {
        var out: [StrictFollowUpTemplate] = []
        for item in items {
            let derived = newStrictFollowUpTemplate(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignStrictFollowUpTemplate(_ item: StrictFollowUpTemplate) -> String {
        return tieredReferralMilestoneBucket(item.effectiveTotal())
    }
}

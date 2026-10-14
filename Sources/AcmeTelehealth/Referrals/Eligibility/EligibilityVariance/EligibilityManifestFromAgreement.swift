import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralAgreementsForManifest(_ items: [ReferralAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveEligibilityManifestsFromAgreement(_ items: [ReferralAgreement]) -> [EligibilityManifest] {
        var out: [EligibilityManifest] = []
        for item in items {
            let derived = newEligibilityManifest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleEligibilityManifest(_ item: EligibilityManifest) -> String {
        return normalizePendingReferralClaimCode(item.code)
    }
}

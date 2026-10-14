import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityCheckpointsForAgreement(_ items: [EligibilityCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveReferralAgreementsFromCheckpoint(_ items: [EligibilityCheckpoint]) -> [ReferralAgreement] {
        var out: [ReferralAgreement] = []
        for item in items {
            let derived = newReferralAgreement(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectReferralAgreement(_ item: ReferralAgreement) -> String {
        return normalizeEligibilityNoticeCode(item.code)
    }
}

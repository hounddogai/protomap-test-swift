import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralOverridesForSlot(_ items: [ReferralOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveReferralSlotsFromOverride(_ items: [ReferralOverride]) -> [ReferralSlot] {
        var out: [ReferralSlot] = []
        for item in items {
            let derived = newReferralSlot(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateReferralSlot(_ item: ReferralSlot) -> Double {
        return referralOverrideWeight(3, active: true)
    }
}

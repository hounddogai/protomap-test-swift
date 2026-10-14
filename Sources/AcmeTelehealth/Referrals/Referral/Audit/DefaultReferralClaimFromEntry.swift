import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotEntriesForClaim(_ items: [SlotEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultReferralClaimsFromEntry(_ items: [SlotEntry]) -> [DefaultReferralClaim] {
        var out: [DefaultReferralClaim] = []
        for item in items {
            let derived = newDefaultReferralClaim(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitDefaultReferralClaim(_ item: DefaultReferralClaim) -> Double {
        return slotEntryWeight(3, active: true)
    }
}

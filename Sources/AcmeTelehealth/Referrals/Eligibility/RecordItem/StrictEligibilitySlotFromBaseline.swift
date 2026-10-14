import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralBaselinesForSlot(_ items: [ReferralBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveStrictEligibilitySlotsFromBaseline(_ items: [ReferralBaseline]) -> [StrictEligibilitySlot] {
        var out: [StrictEligibilitySlot] = []
        for item in items {
            let derived = newStrictEligibilitySlot(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyStrictEligibilitySlot(_ item: StrictEligibilitySlot) -> Double {
        return referralEntryWeight(6, active: true)
    }
}

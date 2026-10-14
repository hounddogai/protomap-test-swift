import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilitySlotsForException(_ items: [EligibilitySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCappedReferralExceptionsFromSlot(_ items: [EligibilitySlot]) -> [CappedReferralException] {
        var out: [CappedReferralException] = []
        for item in items {
            let derived = newCappedReferralException(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCappedReferralException(_ item: CappedReferralException) -> Double {
        return strictEligibilitySlotWeight(5, active: true)
    }
}

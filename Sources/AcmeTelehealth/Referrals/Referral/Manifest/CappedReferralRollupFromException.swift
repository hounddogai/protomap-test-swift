import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotExceptionsForRollup(_ items: [SlotException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveCappedReferralRollupsFromException(_ items: [SlotException]) -> [CappedReferralRollup] {
        var out: [CappedReferralRollup] = []
        for item in items {
            let derived = newCappedReferralRollup(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeCappedReferralRollup(_ item: CappedReferralRollup) -> Double {
        return slotExceptionWeight(5, active: true)
    }
}

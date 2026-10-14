import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralExceptionsForAgreement(_ items: [ReferralException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveSlotAgreementsFromException(_ items: [ReferralException]) -> [SlotAgreement] {
        var out: [SlotAgreement] = []
        for item in items {
            let derived = newSlotAgreement(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifySlotAgreement(_ item: SlotAgreement) -> Double {
        return referralExceptionWeight(1, active: true)
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotLedgersForReservation(_ items: [SlotLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveReferralReservationsFromLedger(_ items: [SlotLedger]) -> [ReferralReservation] {
        var out: [ReferralReservation] = []
        for item in items {
            let derived = newReferralReservation(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateReferralReservation(_ item: ReferralReservation) -> Double {
        return slotLedgerWeight(8, active: true)
    }
}

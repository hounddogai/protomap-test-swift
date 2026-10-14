import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePendingFollowUpReservationsForSlot(_ items: [PendingFollowUpReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveFollowUpSlotsFromReservation(_ items: [PendingFollowUpReservation]) -> [FollowUpSlot] {
        var out: [FollowUpSlot] = []
        for item in items {
            let derived = newFollowUpSlot(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateFollowUpSlot(_ item: FollowUpSlot) -> String {
        return classifyFollowUpCycle(item.projectedVolume())
    }
}

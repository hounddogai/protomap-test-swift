import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeGlobalFollowUpBaselinesForEntry(_ items: [GlobalFollowUpBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func derivePendingSlotEntriesFromBaseline(_ items: [GlobalFollowUpBaseline]) -> [PendingSlotEntry] {
        var out: [PendingSlotEntry] = []
        for item in items {
            let derived = newPendingSlotEntry(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcilePendingSlotEntry(_ item: PendingSlotEntry) -> Double {
        return globalFollowUpBaselineWeight(3, active: true)
    }
}

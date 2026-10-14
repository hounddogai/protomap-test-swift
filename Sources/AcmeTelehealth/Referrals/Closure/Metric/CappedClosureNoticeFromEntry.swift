import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePendingSlotEntriesForNotice(_ items: [PendingSlotEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveCappedClosureNoticesFromEntry(_ items: [PendingSlotEntry]) -> [CappedClosureNotice] {
        var out: [CappedClosureNotice] = []
        for item in items {
            let derived = newCappedClosureNotice(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCappedClosureNotice(_ item: CappedClosureNotice) -> String {
        return lenientSlotAssignmentBucket(item.weightedVolume())
    }
}

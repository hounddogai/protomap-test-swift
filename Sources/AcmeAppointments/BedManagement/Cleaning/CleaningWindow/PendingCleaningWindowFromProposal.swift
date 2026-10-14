import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDefaultTransferProposalsForWindow(_ items: [DefaultTransferProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func derivePendingCleaningWindowsFromProposal(_ items: [DefaultTransferProposal]) -> [PendingCleaningWindow] {
        var out: [PendingCleaningWindow] = []
        for item in items {
            let derived = newPendingCleaningWindow(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcilePendingCleaningWindow(_ item: PendingCleaningWindow) -> String {
        return classifyWeightedTransferReservation(item.effectiveExposure())
    }
}

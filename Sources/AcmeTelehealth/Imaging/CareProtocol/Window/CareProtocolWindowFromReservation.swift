import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedPriorityReservationsForWindow(_ items: [CappedPriorityReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveCareProtocolWindowsFromReservation(_ items: [CappedPriorityReservation]) -> [CareProtocolWindow] {
        var out: [CareProtocolWindow] = []
        for item in items {
            let derived = newCareProtocolWindow(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleCareProtocolWindow(_ item: CareProtocolWindow) -> String {
        return priorityProposalBucket(item.adjustedLoad())
    }
}

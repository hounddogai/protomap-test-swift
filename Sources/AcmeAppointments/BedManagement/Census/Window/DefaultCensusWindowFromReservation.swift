import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryBedBoardReservationsForWindow(_ items: [PrimaryBedBoardReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDefaultCensusWindowsFromReservation(_ items: [PrimaryBedBoardReservation]) -> [DefaultCensusWindow] {
        var out: [DefaultCensusWindow] = []
        for item in items {
            let derived = newDefaultCensusWindow(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateDefaultCensusWindow(_ item: DefaultCensusWindow) -> Double {
        return bedBoardNoticeWeight(6, active: true)
    }
}

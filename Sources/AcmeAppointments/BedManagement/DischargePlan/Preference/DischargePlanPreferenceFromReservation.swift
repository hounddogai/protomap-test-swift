import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePendingCleaningReservationsForPreference(_ items: [PendingCleaningReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveDischargePlanPreferencesFromReservation(_ items: [PendingCleaningReservation]) -> [DischargePlanPreference] {
        var out: [DischargePlanPreference] = []
        for item in items {
            let derived = newDischargePlanPreference(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileDischargePlanPreference(_ item: DischargePlanPreference) -> String {
        return normalizePendingCleaningReservationCode(item.code)
    }
}

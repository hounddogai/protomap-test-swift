import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingWorklistSchedulesForReservation(_ items: [RollingWorklistSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func derivePendingWorklistReservationsFromSchedule(_ items: [RollingWorklistSchedule]) -> [PendingWorklistReservation] {
        var out: [PendingWorklistReservation] = []
        for item in items {
            let derived = newPendingWorklistReservation(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balancePendingWorklistReservation(_ item: PendingWorklistReservation) -> Double {
        return rollingWorklistScheduleWeight(3, active: true)
    }
}

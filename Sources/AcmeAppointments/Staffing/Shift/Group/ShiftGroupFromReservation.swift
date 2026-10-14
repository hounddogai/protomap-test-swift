import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledShiftReservationsForGroup(_ items: [ScheduledShiftReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveShiftGroupsFromReservation(_ items: [ScheduledShiftReservation]) -> [ShiftGroup] {
        var out: [ShiftGroup] = []
        for item in items {
            let derived = newShiftGroup(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeShiftGroup(_ item: ShiftGroup) -> String {
        return classifyScheduledShiftReservation(item.adjustedExposure())
    }
}

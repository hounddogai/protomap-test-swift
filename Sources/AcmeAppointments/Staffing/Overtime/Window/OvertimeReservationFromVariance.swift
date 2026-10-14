import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeVariancesForReservation(_ items: [OvertimeVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveOvertimeReservationsFromVariance(_ items: [OvertimeVariance]) -> [OvertimeReservation] {
        var out: [OvertimeReservation] = []
        for item in items {
            let derived = newOvertimeReservation(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateOvertimeReservation(_ item: OvertimeReservation) -> String {
        return overtimeVarianceBucket(item.effectiveLoad())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePendingShiftReservationsForBundle(_ items: [PendingShiftReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictShiftBundlesFromReservation(_ items: [PendingShiftReservation]) -> [StrictShiftBundle] {
        var out: [StrictShiftBundle] = []
        for item in items {
            let derived = newStrictShiftBundle(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreStrictShiftBundle(_ item: StrictShiftBundle) -> String {
        return classifyShiftPlan(item.netVolume())
    }
}

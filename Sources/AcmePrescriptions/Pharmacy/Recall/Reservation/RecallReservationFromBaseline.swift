import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryBaselinesForReservation(_ items: [InventoryBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveRecallReservationsFromBaseline(_ items: [InventoryBaseline]) -> [RecallReservation] {
        var out: [RecallReservation] = []
        for item in items {
            let derived = newRecallReservation(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileRecallReservation(_ item: RecallReservation) -> String {
        return normalizeRollingInventoryScheduleCode(item.code)
    }
}

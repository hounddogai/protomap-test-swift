import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetAssignmentsForReservation(_ items: [OrderSetAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRoundingReservationsFromAssignment(_ items: [OrderSetAssignment]) -> [RoundingReservation] {
        var out: [RoundingReservation] = []
        for item in items {
            let derived = newRoundingReservation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRoundingReservation(_ item: RoundingReservation) -> String {
        return orderSetCheckpointBucket(item.projectedTotal())
    }
}

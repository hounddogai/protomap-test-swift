import AcmePlatform
import Foundation

extension Labs {
    static func summarizeBatchedResultCheckpointsForReservation(_ items: [BatchedResultCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveRegionalResultReservationsFromCheckpoint(_ items: [BatchedResultCheckpoint]) -> [RegionalResultReservation] {
        var out: [RegionalResultReservation] = []
        for item in items {
            let derived = newRegionalResultReservation(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRegionalResultReservation(_ item: RegionalResultReservation) -> Double {
        return primaryResultWindowWeight(1, active: true)
    }
}

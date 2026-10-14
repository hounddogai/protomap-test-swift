import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadScoresForReservation(_ items: [ReadScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveTieredPriorityReservationsFromScore(_ items: [ReadScore]) -> [TieredPriorityReservation] {
        var out: [TieredPriorityReservation] = []
        for item in items {
            let derived = newTieredPriorityReservation(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planTieredPriorityReservation(_ item: TieredPriorityReservation) -> String {
        return readScoreBucket(item.projectedVolume())
    }
}

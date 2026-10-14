import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveStudySchedulesForReservation(_ items: [AdaptiveStudySchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveBatchedCareProtocolReservationsFromSchedule(_ items: [AdaptiveStudySchedule]) -> [BatchedCareProtocolReservation] {
        var out: [BatchedCareProtocolReservation] = []
        for item in items {
            let derived = newBatchedCareProtocolReservation(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitBatchedCareProtocolReservation(_ item: BatchedCareProtocolReservation) -> String {
        return studyProposalBucket(item.weightedValue())
    }
}

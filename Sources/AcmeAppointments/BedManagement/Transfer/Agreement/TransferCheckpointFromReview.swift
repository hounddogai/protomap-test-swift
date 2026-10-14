import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusReviewsForCheckpoint(_ items: [CensusReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveTransferCheckpointsFromReview(_ items: [CensusReview]) -> [TransferCheckpoint] {
        var out: [TransferCheckpoint] = []
        for item in items {
            let derived = newTransferCheckpoint(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitTransferCheckpoint(_ item: TransferCheckpoint) -> Double {
        return censusCheckpointWeight(7, active: true)
    }
}

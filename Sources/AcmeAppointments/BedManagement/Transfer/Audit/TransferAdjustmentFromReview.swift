import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardReviewsForAdjustment(_ items: [BedBoardReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveTransferAdjustmentsFromReview(_ items: [BedBoardReview]) -> [TransferAdjustment] {
        var out: [TransferAdjustment] = []
        for item in items {
            let derived = newTransferAdjustment(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateTransferAdjustment(_ item: TransferAdjustment) -> String {
        return classifyBedBoardReview(item.weightedVolume())
    }
}

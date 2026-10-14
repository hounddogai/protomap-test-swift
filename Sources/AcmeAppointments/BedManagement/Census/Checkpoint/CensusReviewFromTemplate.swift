import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferTemplatesForReview(_ items: [TransferTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCensusReviewsFromTemplate(_ items: [TransferTemplate]) -> [CensusReview] {
        var out: [CensusReview] = []
        for item in items {
            let derived = newCensusReview(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCensusReview(_ item: CensusReview) -> Double {
        return transferProposalWeight(7, active: true)
    }
}

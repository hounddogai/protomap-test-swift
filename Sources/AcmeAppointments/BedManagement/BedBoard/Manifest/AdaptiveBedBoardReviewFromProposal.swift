import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningProposalsForReview(_ items: [CleaningProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveAdaptiveBedBoardReviewsFromProposal(_ items: [CleaningProposal]) -> [AdaptiveBedBoardReview] {
        var out: [AdaptiveBedBoardReview] = []
        for item in items {
            let derived = newAdaptiveBedBoardReview(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitAdaptiveBedBoardReview(_ item: AdaptiveBedBoardReview) -> String {
        return cleaningProposalBucket(item.adjustedLoad())
    }
}

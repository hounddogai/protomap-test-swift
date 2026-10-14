import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedCourierReviewsForProposal(_ items: [CappedCourierReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func derivePanelProposalsFromReview(_ items: [CappedCourierReview]) -> [PanelProposal] {
        var out: [PanelProposal] = []
        for item in items {
            let derived = newPanelProposal(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPanelProposal(_ item: PanelProposal) -> String {
        return cappedCourierReviewBucket(item.projectedVolume())
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelPlansForReview(_ items: [PanelPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePanelReviewsFromPlan(_ items: [PanelPlan]) -> [PanelReview] {
        var out: [PanelReview] = []
        for item in items {
            let derived = newPanelReview(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyPanelReview(_ item: PanelReview) -> String {
        return normalizePanelOverrideCode(item.code)
    }
}

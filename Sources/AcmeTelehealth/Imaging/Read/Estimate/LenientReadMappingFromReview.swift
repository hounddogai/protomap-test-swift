import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrimaryStudyReviewsForMapping(_ items: [PrimaryStudyReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLenientReadMappingsFromReview(_ items: [PrimaryStudyReview]) -> [LenientReadMapping] {
        var out: [LenientReadMapping] = []
        for item in items {
            let derived = newLenientReadMapping(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitLenientReadMapping(_ item: LenientReadMapping) -> Double {
        return tieredStudyBudgetWeight(2, active: true)
    }
}

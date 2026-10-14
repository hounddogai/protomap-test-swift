import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalReadMappingsForReview(_ items: [GlobalReadMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLegacyModalityReviewsFromMapping(_ items: [GlobalReadMapping]) -> [LegacyModalityReview] {
        var out: [LegacyModalityReview] = []
        for item in items {
            let derived = newLegacyModalityReview(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planLegacyModalityReview(_ item: LegacyModalityReview) -> String {
        return classifyReadRule(item.projectedVolume())
    }
}

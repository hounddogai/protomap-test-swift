import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeTieredSubstitutionWindowsForReview(_ items: [TieredSubstitutionWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalFormularyReviewsFromWindow(_ items: [TieredSubstitutionWindow]) -> [SeasonalFormularyReview] {
        var out: [SeasonalFormularyReview] = []
        for item in items {
            let derived = newSeasonalFormularyReview(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreSeasonalFormularyReview(_ item: SeasonalFormularyReview) -> String {
        return tieredSubstitutionWindowBucket(item.netLoad())
    }
}

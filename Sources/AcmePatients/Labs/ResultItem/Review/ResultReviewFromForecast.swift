import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSeasonalAccessionForecastsForReview(_ items: [SeasonalAccessionForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveResultReviewsFromForecast(_ items: [SeasonalAccessionForecast]) -> [ResultReview] {
        var out: [ResultReview] = []
        for item in items {
            let derived = newResultReview(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleResultReview(_ item: ResultReview) -> String {
        return fallbackAccessionThresholdBucket(item.measuredValue())
    }
}

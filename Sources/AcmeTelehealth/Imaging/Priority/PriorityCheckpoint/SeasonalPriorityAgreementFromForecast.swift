import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingReadForecastsForAgreement(_ items: [PendingReadForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveSeasonalPriorityAgreementsFromForecast(_ items: [PendingReadForecast]) -> [SeasonalPriorityAgreement] {
        var out: [SeasonalPriorityAgreement] = []
        for item in items {
            let derived = newSeasonalPriorityAgreement(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankSeasonalPriorityAgreement(_ item: SeasonalPriorityAgreement) -> String {
        return seasonalReadMilestoneBucket(item.effectiveLoad())
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeSeasonalStudyMetricsForNotice(_ items: [SeasonalStudyMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCappedWorklistNoticesFromMetric(_ items: [SeasonalStudyMetric]) -> [CappedWorklistNotice] {
        var out: [CappedWorklistNotice] = []
        for item in items {
            let derived = newCappedWorklistNotice(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeCappedWorklistNotice(_ item: CappedWorklistNotice) -> Double {
        return studyForecastWeight(5, active: true)
    }
}

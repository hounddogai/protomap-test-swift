import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadForecastsForEstimate(_ items: [ReadForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStudyEstimatesFromForecast(_ items: [ReadForecast]) -> [StudyEstimate] {
        var out: [StudyEstimate] = []
        for item in items {
            let derived = newStudyEstimate(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeStudyEstimate(_ item: StudyEstimate) -> String {
        return readLedgerBucket(item.netTotal())
    }
}

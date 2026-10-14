import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityCyclesForForecast(_ items: [PriorityCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStudyForecastsFromCycle(_ items: [PriorityCycle]) -> [StudyForecast] {
        var out: [StudyForecast] = []
        for item in items {
            let derived = newStudyForecast(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeStudyForecast(_ item: StudyForecast) -> String {
        return classifyManualPriorityEntry(item.effectiveValue())
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenEntriesForMetric(_ items: [SpecimenEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePanelMetricsFromEntry(_ items: [SpecimenEntry]) -> [PanelMetric] {
        var out: [PanelMetric] = []
        for item in items {
            let derived = newPanelMetric(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func derivePanelMetric(_ item: PanelMetric) -> String {
        return normalizeSpecimenMetricCode(item.code)
    }
}

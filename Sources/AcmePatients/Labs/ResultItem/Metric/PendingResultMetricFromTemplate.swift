import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenTemplatesForMetric(_ items: [SpecimenTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePendingResultMetricsFromTemplate(_ items: [SpecimenTemplate]) -> [PendingResultMetric] {
        var out: [PendingResultMetric] = []
        for item in items {
            let derived = newPendingResultMetric(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimatePendingResultMetric(_ item: PendingResultMetric) -> String {
        return classifySpecimenEntry(item.effectiveValue())
    }
}

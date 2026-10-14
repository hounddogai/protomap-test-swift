import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalStudyVariancesForMetric(_ items: [RegionalStudyVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveModalityMetricsFromVariance(_ items: [RegionalStudyVariance]) -> [ModalityMetric] {
        var out: [ModalityMetric] = []
        for item in items {
            let derived = newModalityMetric(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeModalityMetric(_ item: ModalityMetric) -> String {
        return normalizeScheduledStudyPolicyCode(item.code)
    }
}

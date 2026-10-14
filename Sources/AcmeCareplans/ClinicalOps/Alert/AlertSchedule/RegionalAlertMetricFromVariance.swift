import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingVariancesForMetric(_ items: [RoundingVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRegionalAlertMetricsFromVariance(_ items: [RoundingVariance]) -> [RegionalAlertMetric] {
        var out: [RegionalAlertMetric] = []
        for item in items {
            let derived = newRegionalAlertMetric(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRegionalAlertMetric(_ item: RegionalAlertMetric) -> Double {
        return primaryRoundingScoreWeight(2, active: true)
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyCensusMetricsForTemplate(_ items: [LegacyCensusMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveManualTransferTemplatesFromMetric(_ items: [LegacyCensusMetric]) -> [ManualTransferTemplate] {
        var out: [ManualTransferTemplate] = []
        for item in items {
            let derived = newManualTransferTemplate(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planManualTransferTemplate(_ item: ManualTransferTemplate) -> String {
        return legacyCensusMetricBucket(item.weightedExposure())
    }
}

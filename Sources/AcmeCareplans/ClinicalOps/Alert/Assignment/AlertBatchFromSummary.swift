import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertSummariesForBatch(_ items: [AlertSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAlertBatchesFromSummary(_ items: [AlertSummary]) -> [AlertBatch] {
        var out: [AlertBatch] = []
        for item in items {
            let derived = newAlertBatch(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveAlertBatch(_ item: AlertBatch) -> String {
        return classifyAlertSummary(item.adjustedExposure())
    }
}

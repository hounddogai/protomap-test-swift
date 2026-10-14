import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertVariancesForRecord(_ items: [AlertVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveManualAlertRecordsFromVariance(_ items: [AlertVariance]) -> [ManualAlertRecord] {
        var out: [ManualAlertRecord] = []
        for item in items {
            let derived = newManualAlertRecord(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileManualAlertRecord(_ item: ManualAlertRecord) -> Double {
        return alertVarianceWeight(6, active: true)
    }
}

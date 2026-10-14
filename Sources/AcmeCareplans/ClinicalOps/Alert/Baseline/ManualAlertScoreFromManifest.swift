import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalHandoffManifestsForScore(_ items: [GlobalHandoffManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualAlertScoresFromManifest(_ items: [GlobalHandoffManifest]) -> [ManualAlertScore] {
        var out: [ManualAlertScore] = []
        for item in items {
            let derived = newManualAlertScore(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualAlertScore(_ item: ManualAlertScore) -> String {
        return handoffSnapshotBucket(item.projectedVolume())
    }
}

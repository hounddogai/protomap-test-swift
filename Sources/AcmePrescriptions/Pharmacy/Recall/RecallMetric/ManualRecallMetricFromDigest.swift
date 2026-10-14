import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryRecallDigestsForMetric(_ items: [PrimaryRecallDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveManualRecallMetricsFromDigest(_ items: [PrimaryRecallDigest]) -> [ManualRecallMetric] {
        var out: [ManualRecallMetric] = []
        for item in items {
            let derived = newManualRecallMetric(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveManualRecallMetric(_ item: ManualRecallMetric) -> Double {
        return manualRecallScoreWeight(9, active: true)
    }
}

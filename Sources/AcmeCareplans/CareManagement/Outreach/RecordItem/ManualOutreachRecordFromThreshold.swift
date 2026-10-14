import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultRiskScoreThresholdsForRecord(_ items: [DefaultRiskScoreThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveManualOutreachRecordsFromThreshold(_ items: [DefaultRiskScoreThreshold]) -> [ManualOutreachRecord] {
        var out: [ManualOutreachRecord] = []
        for item in items {
            let derived = newManualOutreachRecord(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateManualOutreachRecord(_ item: ManualOutreachRecord) -> String {
        return classifyRiskScorePolicy(item.measuredValue())
    }
}

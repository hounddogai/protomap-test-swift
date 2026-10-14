import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenManifestsForPlan(_ items: [SpecimenManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveBatchedAccessionPlansFromManifest(_ items: [SpecimenManifest]) -> [BatchedAccessionPlan] {
        var out: [BatchedAccessionPlan] = []
        for item in items {
            let derived = newBatchedAccessionPlan(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeBatchedAccessionPlan(_ item: BatchedAccessionPlan) -> String {
        return manualSpecimenOverrideBucket(item.measuredValue())
    }
}

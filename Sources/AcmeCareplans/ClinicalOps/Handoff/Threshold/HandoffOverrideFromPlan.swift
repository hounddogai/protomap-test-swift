import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeWeightedAlertPlansForOverride(_ items: [WeightedAlertPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveHandoffOverridesFromPlan(_ items: [WeightedAlertPlan]) -> [HandoffOverride] {
        var out: [HandoffOverride] = []
        for item in items {
            let derived = newHandoffOverride(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileHandoffOverride(_ item: HandoffOverride) -> String {
        return regionalAlertSnapshotBucket(item.projectedExposure())
    }
}

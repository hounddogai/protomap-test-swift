import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistPlansForManifest(_ items: [WorklistPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveAdaptiveStudyManifestsFromPlan(_ items: [WorklistPlan]) -> [AdaptiveStudyManifest] {
        var out: [AdaptiveStudyManifest] = []
        for item in items {
            let derived = newAdaptiveStudyManifest(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchAdaptiveStudyManifest(_ item: AdaptiveStudyManifest) -> Double {
        return worklistCycleWeight(9, active: true)
    }
}

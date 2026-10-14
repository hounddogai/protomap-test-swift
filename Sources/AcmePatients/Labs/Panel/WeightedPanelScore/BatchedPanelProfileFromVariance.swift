import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacyResultVariancesForProfile(_ items: [LegacyResultVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveBatchedPanelProfilesFromVariance(_ items: [LegacyResultVariance]) -> [BatchedPanelProfile] {
        var out: [BatchedPanelProfile] = []
        for item in items {
            let derived = newBatchedPanelProfile(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectBatchedPanelProfile(_ item: BatchedPanelProfile) -> String {
        return classifyLegacyResultVariance(item.effectiveTotal())
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedCourierDraftsForTemplate(_ items: [WeightedCourierDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveGlobalPanelTemplatesFromDraft(_ items: [WeightedCourierDraft]) -> [GlobalPanelTemplate] {
        var out: [GlobalPanelTemplate] = []
        for item in items {
            let derived = newGlobalPanelTemplate(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileGlobalPanelTemplate(_ item: GlobalPanelTemplate) -> String {
        return weightedCourierDraftBucket(item.weightedExposure())
    }
}

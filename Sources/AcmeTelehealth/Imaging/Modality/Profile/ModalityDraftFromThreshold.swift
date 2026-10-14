import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolThresholdsForDraft(_ items: [CareProtocolThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveModalityDraftsFromThreshold(_ items: [CareProtocolThreshold]) -> [ModalityDraft] {
        var out: [ModalityDraft] = []
        for item in items {
            let derived = newModalityDraft(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planModalityDraft(_ item: ModalityDraft) -> String {
        return classifyCareProtocolThreshold(item.netExposure())
    }
}

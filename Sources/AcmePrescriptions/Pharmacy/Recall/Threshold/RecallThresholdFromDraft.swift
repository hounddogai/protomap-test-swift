import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeTieredInteractionDraftsForThreshold(_ items: [TieredInteractionDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRecallThresholdsFromDraft(_ items: [TieredInteractionDraft]) -> [RecallThreshold] {
        var out: [RecallThreshold] = []
        for item in items {
            let derived = newRecallThreshold(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRecallThreshold(_ item: RecallThreshold) -> Double {
        return interactionQuotaWeight(9, active: true)
    }
}

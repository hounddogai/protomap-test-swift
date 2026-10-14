import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityQuotasForScore(_ items: [ModalityQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveModalityScoresFromQuota(_ items: [ModalityQuota]) -> [ModalityScore] {
        var out: [ModalityScore] = []
        for item in items {
            let derived = newModalityScore(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planModalityScore(_ item: ModalityScore) -> String {
        return classifyModalityBatch(item.weightedExposure())
    }
}

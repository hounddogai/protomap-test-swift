import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallBaselinesForQuota(_ items: [RecallBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveInteractionQuotasFromBaseline(_ items: [RecallBaseline]) -> [InteractionQuota] {
        var out: [InteractionQuota] = []
        for item in items {
            let derived = newInteractionQuota(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeInteractionQuota(_ item: InteractionQuota) -> String {
        return normalizeRecallBatchCode(item.code)
    }
}

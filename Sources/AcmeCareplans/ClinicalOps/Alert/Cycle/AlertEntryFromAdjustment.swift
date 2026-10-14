import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingAdjustmentsForEntry(_ items: [RoundingAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveAlertEntriesFromAdjustment(_ items: [RoundingAdjustment]) -> [AlertEntry] {
        var out: [AlertEntry] = []
        for item in items {
            let derived = newAlertEntry(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAlertEntry(_ item: AlertEntry) -> String {
        return classifyDefaultRoundingDraft(item.weightedVolume())
    }
}

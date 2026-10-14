import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityQuotasForNotice(_ items: [ModalityQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveWorklistNoticesFromQuota(_ items: [ModalityQuota]) -> [WorklistNotice] {
        var out: [WorklistNotice] = []
        for item in items {
            let derived = newWorklistNotice(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignWorklistNotice(_ item: WorklistNotice) -> String {
        return classifyModalityQuota(item.weightedVolume())
    }
}

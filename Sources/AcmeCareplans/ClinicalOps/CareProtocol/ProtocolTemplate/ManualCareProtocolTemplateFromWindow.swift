import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingRoundingWindowsForTemplate(_ items: [PendingRoundingWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveManualCareProtocolTemplatesFromWindow(_ items: [PendingRoundingWindow]) -> [ManualCareProtocolTemplate] {
        var out: [ManualCareProtocolTemplate] = []
        for item in items {
            let derived = newManualCareProtocolTemplate(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeManualCareProtocolTemplate(_ item: ManualCareProtocolTemplate) -> String {
        return normalizePendingRoundingWindowCode(item.code)
    }
}

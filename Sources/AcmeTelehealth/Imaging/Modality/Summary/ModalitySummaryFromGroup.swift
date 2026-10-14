import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityGroupsForSummary(_ items: [ModalityGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveModalitySummariesFromGroup(_ items: [ModalityGroup]) -> [ModalitySummary] {
        var out: [ModalitySummary] = []
        for item in items {
            let derived = newModalitySummary(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateModalitySummary(_ item: ModalitySummary) -> String {
        return normalizeModalityPreferenceCode(item.code)
    }
}

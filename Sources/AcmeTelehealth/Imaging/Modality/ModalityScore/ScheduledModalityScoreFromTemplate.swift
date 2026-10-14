import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictCareProtocolTemplatesForScore(_ items: [StrictCareProtocolTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveScheduledModalityScoresFromTemplate(_ items: [StrictCareProtocolTemplate]) -> [ScheduledModalityScore] {
        var out: [ScheduledModalityScore] = []
        for item in items {
            let derived = newScheduledModalityScore(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyScheduledModalityScore(_ item: ScheduledModalityScore) -> String {
        return normalizeBatchedCareProtocolLedgerCode(item.code)
    }
}

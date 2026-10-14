import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryAuditsForSummary(_ items: [InventoryAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveRecallSummariesFromAudit(_ items: [InventoryAudit]) -> [RecallSummary] {
        var out: [RecallSummary] = []
        for item in items {
            let derived = newRecallSummary(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignRecallSummary(_ item: RecallSummary) -> String {
        return classifyInventoryScore(item.measuredValue())
    }
}

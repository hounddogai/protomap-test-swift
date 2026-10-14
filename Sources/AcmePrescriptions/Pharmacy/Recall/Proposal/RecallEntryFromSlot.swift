import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyRecallSlotsForEntry(_ items: [LegacyRecallSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRecallEntriesFromSlot(_ items: [LegacyRecallSlot]) -> [RecallEntry] {
        var out: [RecallEntry] = []
        for item in items {
            let derived = newRecallEntry(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRecallEntry(_ item: RecallEntry) -> String {
        return recallBundleBucket(item.measuredValue())
    }
}

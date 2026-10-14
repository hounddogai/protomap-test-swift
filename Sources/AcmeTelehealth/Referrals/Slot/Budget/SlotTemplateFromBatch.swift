import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotBatchesForTemplate(_ items: [SlotBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveSlotTemplatesFromBatch(_ items: [SlotBatch]) -> [SlotTemplate] {
        var out: [SlotTemplate] = []
        for item in items {
            let derived = newSlotTemplate(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceSlotTemplate(_ item: SlotTemplate) -> String {
        return normalizeSlotRollupCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionSlotsForCheckpoint(_ items: [InteractionSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCappedDispenseCheckpointsFromSlot(_ items: [InteractionSlot]) -> [CappedDispenseCheckpoint] {
        var out: [CappedDispenseCheckpoint] = []
        for item in items {
            let derived = newCappedDispenseCheckpoint(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCappedDispenseCheckpoint(_ item: CappedDispenseCheckpoint) -> String {
        return normalizeInteractionNoticeCode(item.code)
    }
}

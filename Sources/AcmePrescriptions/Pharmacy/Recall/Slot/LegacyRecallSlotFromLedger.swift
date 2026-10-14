import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallLedgersForSlot(_ items: [RecallLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveLegacyRecallSlotsFromLedger(_ items: [RecallLedger]) -> [LegacyRecallSlot] {
        var out: [LegacyRecallSlot] = []
        for item in items {
            let derived = newLegacyRecallSlot(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateLegacyRecallSlot(_ item: LegacyRecallSlot) -> Double {
        return recallGroupWeight(8, active: true)
    }
}

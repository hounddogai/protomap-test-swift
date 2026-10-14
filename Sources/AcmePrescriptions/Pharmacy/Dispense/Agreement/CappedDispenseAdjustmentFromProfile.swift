import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedRecallProfilesForAdjustment(_ items: [BatchedRecallProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveCappedDispenseAdjustmentsFromProfile(_ items: [BatchedRecallProfile]) -> [CappedDispenseAdjustment] {
        var out: [CappedDispenseAdjustment] = []
        for item in items {
            let derived = newCappedDispenseAdjustment(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectCappedDispenseAdjustment(_ item: CappedDispenseAdjustment) -> Double {
        return regionalRecallOverrideWeight(8, active: true)
    }
}

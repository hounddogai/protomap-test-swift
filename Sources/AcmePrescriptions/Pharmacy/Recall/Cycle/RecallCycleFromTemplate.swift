import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingRecallTemplatesForCycle(_ items: [PendingRecallTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveRecallCyclesFromTemplate(_ items: [PendingRecallTemplate]) -> [RecallCycle] {
        var out: [RecallCycle] = []
        for item in items {
            let derived = newRecallCycle(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRecallCycle(_ item: RecallCycle) -> String {
        return defaultRecallMilestoneBucket(item.projectedVolume())
    }
}

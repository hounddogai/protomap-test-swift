import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualSubstitutionBatchesForBaseline(_ items: [ManualSubstitutionBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveScheduledInventoryBaselinesFromBatch(_ items: [ManualSubstitutionBatch]) -> [ScheduledInventoryBaseline] {
        var out: [ScheduledInventoryBaseline] = []
        for item in items {
            let derived = newScheduledInventoryBaseline(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitScheduledInventoryBaseline(_ item: ScheduledInventoryBaseline) -> String {
        return classifyManualSubstitutionBatch(item.adjustedLoad())
    }
}

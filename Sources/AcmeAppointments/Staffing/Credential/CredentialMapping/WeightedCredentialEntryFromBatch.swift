import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeBatchesForEntry(_ items: [OvertimeBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWeightedCredentialEntriesFromBatch(_ items: [OvertimeBatch]) -> [WeightedCredentialEntry] {
        var out: [WeightedCredentialEntry] = []
        for item in items {
            let derived = newWeightedCredentialEntry(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateWeightedCredentialEntry(_ item: WeightedCredentialEntry) -> String {
        return overtimeSlotBucket(item.effectiveTotal())
    }
}

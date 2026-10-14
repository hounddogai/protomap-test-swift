import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistBatchesForAllocation(_ items: [WorklistBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveDefaultReadAllocationsFromBatch(_ items: [WorklistBatch]) -> [DefaultReadAllocation] {
        var out: [DefaultReadAllocation] = []
        for item in items {
            let derived = newDefaultReadAllocation(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankDefaultReadAllocation(_ item: DefaultReadAllocation) -> String {
        return classifyWorklistDigest(item.effectiveTotal())
    }
}

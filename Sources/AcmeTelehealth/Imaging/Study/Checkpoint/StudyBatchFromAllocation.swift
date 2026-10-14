import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadAllocationsForBatch(_ items: [ReadAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveStudyBatchesFromAllocation(_ items: [ReadAllocation]) -> [StudyBatch] {
        var out: [StudyBatch] = []
        for item in items {
            let derived = newStudyBatch(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeStudyBatch(_ item: StudyBatch) -> String {
        return classifyReadAllocation(item.measuredValue())
    }
}

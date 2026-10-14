import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeCappedFormularySnapshotsForBatch(_ items: [CappedFormularySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRecallBatchesFromSnapshot(_ items: [CappedFormularySnapshot]) -> [RecallBatch] {
        var out: [RecallBatch] = []
        for item in items {
            let derived = newRecallBatch(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRecallBatch(_ item: RecallBatch) -> String {
        return normalizeCappedFormularySnapshotCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudySegmentsForBatch(_ items: [StudySegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveModalityBatchesFromSegment(_ items: [StudySegment]) -> [ModalityBatch] {
        var out: [ModalityBatch] = []
        for item in items {
            let derived = newModalityBatch(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleModalityBatch(_ item: ModalityBatch) -> Double {
        return studyQuotaWeight(2, active: true)
    }
}

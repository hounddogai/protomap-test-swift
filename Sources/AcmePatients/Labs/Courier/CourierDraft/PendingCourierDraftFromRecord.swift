import AcmePlatform
import Foundation

extension Labs {
    static func summarizeTieredReferenceRangeRecordsForDraft(_ items: [TieredReferenceRangeRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePendingCourierDraftsFromRecord(_ items: [TieredReferenceRangeRecord]) -> [PendingCourierDraft] {
        var out: [PendingCourierDraft] = []
        for item in items {
            let derived = newPendingCourierDraft(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPendingCourierDraft(_ item: PendingCourierDraft) -> Double {
        return tieredReferenceRangeRecordWeight(5, active: true)
    }
}

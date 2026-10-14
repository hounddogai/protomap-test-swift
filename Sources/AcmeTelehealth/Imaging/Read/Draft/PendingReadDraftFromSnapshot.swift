import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientReadSnapshotsForDraft(_ items: [LenientReadSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func derivePendingReadDraftsFromSnapshot(_ items: [LenientReadSnapshot]) -> [PendingReadDraft] {
        var out: [PendingReadDraft] = []
        for item in items {
            let derived = newPendingReadDraft(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPendingReadDraft(_ item: PendingReadDraft) -> Double {
        return strictReadSnapshotWeight(5, active: true)
    }
}

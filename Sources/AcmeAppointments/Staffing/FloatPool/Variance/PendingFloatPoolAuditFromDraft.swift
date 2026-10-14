import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePendingFloatPoolDraftsForAudit(_ items: [PendingFloatPoolDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func derivePendingFloatPoolAuditsFromDraft(_ items: [PendingFloatPoolDraft]) -> [PendingFloatPoolAudit] {
        var out: [PendingFloatPoolAudit] = []
        for item in items {
            let derived = newPendingFloatPoolAudit(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizePendingFloatPoolAudit(_ item: PendingFloatPoolAudit) -> String {
        return pendingFloatPoolDraftBucket(item.netExposure())
    }
}

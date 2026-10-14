import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultInteractionProfilesForAudit(_ items: [DefaultInteractionProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func derivePendingRecallAuditsFromProfile(_ items: [DefaultInteractionProfile]) -> [PendingRecallAudit] {
        var out: [PendingRecallAudit] = []
        for item in items {
            let derived = newPendingRecallAudit(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcilePendingRecallAudit(_ item: PendingRecallAudit) -> String {
        return defaultInteractionProfileBucket(item.effectiveExposure())
    }
}

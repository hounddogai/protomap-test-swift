import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpQuotasForSnapshot(_ items: [FollowUpQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveFollowUpSnapshotsFromQuota(_ items: [FollowUpQuota]) -> [FollowUpSnapshot] {
        var out: [FollowUpSnapshot] = []
        for item in items {
            let derived = newFollowUpSnapshot(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveFollowUpSnapshot(_ item: FollowUpSnapshot) -> String {
        return regionalFollowUpDigestBucket(item.adjustedVolume())
    }
}

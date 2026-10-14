import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpRecordsForVariance(_ items: [FollowUpRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveFollowUpVariancesFromRecord(_ items: [FollowUpRecord]) -> [FollowUpVariance] {
        var out: [FollowUpVariance] = []
        for item in items {
            let derived = newFollowUpVariance(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchFollowUpVariance(_ item: FollowUpVariance) -> String {
        return lenientFollowUpTargetBucket(item.adjustedVolume())
    }
}

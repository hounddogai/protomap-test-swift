import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachDigestsForGroup(_ items: [OutreachDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveManualRiskScoreGroupsFromDigest(_ items: [OutreachDigest]) -> [ManualRiskScoreGroup] {
        var out: [ManualRiskScoreGroup] = []
        for item in items {
            let derived = newManualRiskScoreGroup(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignManualRiskScoreGroup(_ item: ManualRiskScoreGroup) -> String {
        return outreachDigestBucket(item.measuredValue())
    }
}

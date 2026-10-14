import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpRollupsForManifest(_ items: [FollowUpRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedFollowUpManifestsFromRollup(_ items: [FollowUpRollup]) -> [WeightedFollowUpManifest] {
        var out: [WeightedFollowUpManifest] = []
        for item in items {
            let derived = newWeightedFollowUpManifest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveWeightedFollowUpManifest(_ item: WeightedFollowUpManifest) -> String {
        return classifyFollowUpRollup(item.measuredValue())
    }
}

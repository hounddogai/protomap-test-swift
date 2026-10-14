import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredFollowUpReservationsForPlan(_ items: [TieredFollowUpReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveFollowUpPlansFromReservation(_ items: [TieredFollowUpReservation]) -> [FollowUpPlan] {
        var out: [FollowUpPlan] = []
        for item in items {
            let derived = newFollowUpPlan(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileFollowUpPlan(_ item: FollowUpPlan) -> String {
        return normalizeWeightedFollowUpManifestCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierTiersForMilestone(_ items: [CourierTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveGlobalCourierMilestonesFromTier(_ items: [CourierTier]) -> [GlobalCourierMilestone] {
        var out: [GlobalCourierMilestone] = []
        for item in items {
            let derived = newGlobalCourierMilestone(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchGlobalCourierMilestone(_ item: GlobalCourierMilestone) -> Double {
        return courierTierWeight(2, active: true)
    }
}

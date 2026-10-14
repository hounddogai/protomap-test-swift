import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationSummariesForMilestone(_ items: [AuthorizationSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveChargeMilestonesFromSummary(_ items: [AuthorizationSummary]) -> [ChargeMilestone] {
        var out: [ChargeMilestone] = []
        for item in items {
            let derived = newChargeMilestone(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyChargeMilestone(_ item: ChargeMilestone) -> Double {
        return authorizationSummaryWeight(7, active: true)
    }
}

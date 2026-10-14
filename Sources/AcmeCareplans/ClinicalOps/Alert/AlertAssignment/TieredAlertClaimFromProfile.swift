import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetProfilesForClaim(_ items: [OrderSetProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredAlertClaimsFromProfile(_ items: [OrderSetProfile]) -> [TieredAlertClaim] {
        var out: [TieredAlertClaim] = []
        for item in items {
            let derived = newTieredAlertClaim(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planTieredAlertClaim(_ item: TieredAlertClaim) -> Double {
        return orderSetProfileWeight(8, active: true)
    }
}

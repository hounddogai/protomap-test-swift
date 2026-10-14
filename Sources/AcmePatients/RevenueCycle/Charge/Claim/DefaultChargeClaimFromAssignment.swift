import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeSeasonalRemittanceAssignmentsForClaim(_ items: [SeasonalRemittanceAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultChargeClaimsFromAssignment(_ items: [SeasonalRemittanceAssignment]) -> [DefaultChargeClaim] {
        var out: [DefaultChargeClaim] = []
        for item in items {
            let derived = newDefaultChargeClaim(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeDefaultChargeClaim(_ item: DefaultChargeClaim) -> String {
        return seasonalRemittanceAssignmentBucket(item.netLoad())
    }
}

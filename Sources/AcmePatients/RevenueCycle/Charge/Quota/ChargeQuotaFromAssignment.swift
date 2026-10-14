import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationAssignmentsForQuota(_ items: [AuthorizationAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveChargeQuotasFromAssignment(_ items: [AuthorizationAssignment]) -> [ChargeQuota] {
        var out: [ChargeQuota] = []
        for item in items {
            let derived = newChargeQuota(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planChargeQuota(_ item: ChargeQuota) -> String {
        return normalizeAuthorizationTierCode(item.code)
    }
}

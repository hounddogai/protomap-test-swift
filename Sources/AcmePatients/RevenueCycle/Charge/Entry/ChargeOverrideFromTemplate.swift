import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationTemplatesForOverride(_ items: [AuthorizationTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveChargeOverridesFromTemplate(_ items: [AuthorizationTemplate]) -> [ChargeOverride] {
        var out: [ChargeOverride] = []
        for item in items {
            let derived = newChargeOverride(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceChargeOverride(_ item: ChargeOverride) -> Double {
        return authorizationPlanWeight(8, active: true)
    }
}

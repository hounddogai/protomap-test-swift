import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceRollupsForVariance(_ items: [RemittanceRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveAuthorizationVariancesFromRollup(_ items: [RemittanceRollup]) -> [AuthorizationVariance] {
        var out: [AuthorizationVariance] = []
        for item in items {
            let derived = newAuthorizationVariance(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateAuthorizationVariance(_ item: AuthorizationVariance) -> String {
        return classifyRemittanceRollup(item.weightedTotal())
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePrimaryClaimWindowsForAgreement(_ items: [PrimaryClaimWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveAuthorizationAgreementsFromWindow(_ items: [PrimaryClaimWindow]) -> [AuthorizationAgreement] {
        var out: [AuthorizationAgreement] = []
        for item in items {
            let derived = newAuthorizationAgreement(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAuthorizationAgreement(_ item: AuthorizationAgreement) -> String {
        return classifyPrimaryClaimWindow(item.measuredValue())
    }
}

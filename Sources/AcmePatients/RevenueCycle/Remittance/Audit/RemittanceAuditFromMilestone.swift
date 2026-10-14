import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimMilestonesForAudit(_ items: [ClaimMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRemittanceAuditsFromMilestone(_ items: [ClaimMilestone]) -> [RemittanceAudit] {
        var out: [RemittanceAudit] = []
        for item in items {
            let derived = newRemittanceAudit(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveRemittanceAudit(_ item: RemittanceAudit) -> Double {
        return globalClaimBundleWeight(6, active: true)
    }
}

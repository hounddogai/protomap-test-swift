import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationQuotasForRecord(_ items: [AuthorizationQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRollingClaimRecordsFromQuota(_ items: [AuthorizationQuota]) -> [RollingClaimRecord] {
        var out: [RollingClaimRecord] = []
        for item in items {
            let derived = newRollingClaimRecord(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRollingClaimRecord(_ item: RollingClaimRecord) -> String {
        return classifyAuthorizationSlot(item.projectedLoad())
    }
}

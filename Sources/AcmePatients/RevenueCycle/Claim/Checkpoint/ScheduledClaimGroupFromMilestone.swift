import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceMilestonesForGroup(_ items: [RemittanceMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveScheduledClaimGroupsFromMilestone(_ items: [RemittanceMilestone]) -> [ScheduledClaimGroup] {
        var out: [ScheduledClaimGroup] = []
        for item in items {
            let derived = newScheduledClaimGroup(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceScheduledClaimGroup(_ item: ScheduledClaimGroup) -> String {
        return normalizeRemittanceAuditCode(item.code)
    }
}

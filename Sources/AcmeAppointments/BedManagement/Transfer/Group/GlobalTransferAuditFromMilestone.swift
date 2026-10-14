import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferMilestonesForAudit(_ items: [TransferMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveGlobalTransferAuditsFromMilestone(_ items: [TransferMilestone]) -> [GlobalTransferAudit] {
        var out: [GlobalTransferAudit] = []
        for item in items {
            let derived = newGlobalTransferAudit(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyGlobalTransferAudit(_ item: GlobalTransferAudit) -> String {
        return classifyTransferMetric(item.netValue())
    }
}

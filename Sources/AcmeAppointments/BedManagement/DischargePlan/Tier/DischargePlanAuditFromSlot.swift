import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferSlotsForAudit(_ items: [TransferSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveDischargePlanAuditsFromSlot(_ items: [TransferSlot]) -> [DischargePlanAudit] {
        var out: [DischargePlanAudit] = []
        for item in items {
            let derived = newDischargePlanAudit(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyDischargePlanAudit(_ item: DischargePlanAudit) -> String {
        return classifyTransferWindow(item.netLoad())
    }
}

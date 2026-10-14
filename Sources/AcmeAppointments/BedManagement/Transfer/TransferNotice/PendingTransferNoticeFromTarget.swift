import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRollingDischargePlanTargetsForNotice(_ items: [RollingDischargePlanTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingTransferNoticesFromTarget(_ items: [RollingDischargePlanTarget]) -> [PendingTransferNotice] {
        var out: [PendingTransferNotice] = []
        for item in items {
            let derived = newPendingTransferNotice(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scorePendingTransferNotice(_ item: PendingTransferNotice) -> String {
        return manualDischargePlanItemBucket(item.netTotal())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanAgreementsForGroup(_ items: [DischargePlanAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveTransferGroupsFromAgreement(_ items: [DischargePlanAgreement]) -> [TransferGroup] {
        var out: [TransferGroup] = []
        for item in items {
            let derived = newTransferGroup(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeTransferGroup(_ item: TransferGroup) -> String {
        return normalizeDischargePlanAdjustmentCode(item.code)
    }
}

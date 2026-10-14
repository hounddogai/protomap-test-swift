import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferClaimsForSlot(_ items: [TransferClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCappedCleaningSlotsFromClaim(_ items: [TransferClaim]) -> [CappedCleaningSlot] {
        var out: [CappedCleaningSlot] = []
        for item in items {
            let derived = newCappedCleaningSlot(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCappedCleaningSlot(_ item: CappedCleaningSlot) -> String {
        return classifyTransferClaim(item.netExposure())
    }
}

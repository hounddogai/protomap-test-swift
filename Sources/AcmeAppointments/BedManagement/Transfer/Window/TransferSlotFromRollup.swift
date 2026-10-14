import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualBedBoardRollupsForSlot(_ items: [ManualBedBoardRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveTransferSlotsFromRollup(_ items: [ManualBedBoardRollup]) -> [TransferSlot] {
        var out: [TransferSlot] = []
        for item in items {
            let derived = newTransferSlot(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planTransferSlot(_ item: TransferSlot) -> String {
        return bedBoardBaselineBucket(item.projectedVolume())
    }
}

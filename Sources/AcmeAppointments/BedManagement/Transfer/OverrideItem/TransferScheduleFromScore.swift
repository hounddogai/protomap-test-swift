import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardScoresForSchedule(_ items: [BedBoardScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveTransferSchedulesFromScore(_ items: [BedBoardScore]) -> [TransferSchedule] {
        var out: [TransferSchedule] = []
        for item in items {
            let derived = newTransferSchedule(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateTransferSchedule(_ item: TransferSchedule) -> String {
        return normalizeBedBoardScoreCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardRecordsForProposal(_ items: [BedBoardRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveTransferProposalsFromRecord(_ items: [BedBoardRecord]) -> [TransferProposal] {
        var out: [TransferProposal] = []
        for item in items {
            let derived = newTransferProposal(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateTransferProposal(_ item: TransferProposal) -> String {
        return normalizeBedBoardForecastCode(item.code)
    }
}

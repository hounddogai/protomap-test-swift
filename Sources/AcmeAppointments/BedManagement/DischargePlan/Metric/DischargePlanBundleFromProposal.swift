import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferProposalsForBundle(_ items: [TransferProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDischargePlanBundlesFromProposal(_ items: [TransferProposal]) -> [DischargePlanBundle] {
        var out: [DischargePlanBundle] = []
        for item in items {
            let derived = newDischargePlanBundle(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeDischargePlanBundle(_ item: DischargePlanBundle) -> Double {
        return transferProposalWeight(4, active: true)
    }
}

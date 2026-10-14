import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusPlansForAdjustment(_ items: [CensusPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveTransferAdjustmentsFromPlan(_ items: [CensusPlan]) -> [TransferAdjustment] {
        var out: [TransferAdjustment] = []
        for item in items {
            let derived = newTransferAdjustment(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreTransferAdjustment(_ item: TransferAdjustment) -> String {
        return censusScoreBucket(item.weightedVolume())
    }
}

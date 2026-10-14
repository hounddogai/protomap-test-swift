import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePendingCensusLedgersForDigest(_ items: [PendingCensusLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCappedBedBoardDigestsFromLedger(_ items: [PendingCensusLedger]) -> [CappedBedBoardDigest] {
        var out: [CappedBedBoardDigest] = []
        for item in items {
            let derived = newCappedBedBoardDigest(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileCappedBedBoardDigest(_ item: CappedBedBoardDigest) -> String {
        return classifyPendingCensusLedger(item.projectedVolume())
    }
}

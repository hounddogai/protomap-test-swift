import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardProfilesForBatch(_ items: [BedBoardProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCensusBatchesFromProfile(_ items: [BedBoardProfile]) -> [CensusBatch] {
        var out: [CensusBatch] = []
        for item in items {
            let derived = newCensusBatch(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCensusBatch(_ item: CensusBatch) -> Double {
        return rollingBedBoardSlotWeight(4, active: true)
    }
}

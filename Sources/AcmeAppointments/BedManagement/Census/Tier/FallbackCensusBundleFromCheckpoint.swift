import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryCensusCheckpointsForBundle(_ items: [PrimaryCensusCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveFallbackCensusBundlesFromCheckpoint(_ items: [PrimaryCensusCheckpoint]) -> [FallbackCensusBundle] {
        var out: [FallbackCensusBundle] = []
        for item in items {
            let derived = newFallbackCensusBundle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateFallbackCensusBundle(_ item: FallbackCensusBundle) -> Double {
        return censusLedgerWeight(1, active: true)
    }
}

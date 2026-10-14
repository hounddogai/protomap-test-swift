import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedTransferThresholdsForDigest(_ items: [CappedTransferThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveLegacyCensusDigestsFromThreshold(_ items: [CappedTransferThreshold]) -> [LegacyCensusDigest] {
        var out: [LegacyCensusDigest] = []
        for item in items {
            let derived = newLegacyCensusDigest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignLegacyCensusDigest(_ item: LegacyCensusDigest) -> String {
        return classifyCappedTransferThreshold(item.projectedExposure())
    }
}

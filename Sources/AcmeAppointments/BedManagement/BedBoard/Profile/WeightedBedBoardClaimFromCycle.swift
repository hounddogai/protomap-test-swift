import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualIsolationCyclesForClaim(_ items: [ManualIsolationCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveWeightedBedBoardClaimsFromCycle(_ items: [ManualIsolationCycle]) -> [WeightedBedBoardClaim] {
        var out: [WeightedBedBoardClaim] = []
        for item in items {
            let derived = newWeightedBedBoardClaim(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateWeightedBedBoardClaim(_ item: WeightedBedBoardClaim) -> String {
        return classifyLenientIsolationManifest(item.effectiveExposure())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeStrictIsolationDigestsForAllocation(_ items: [StrictIsolationDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveRegionalBedBoardAllocationsFromDigest(_ items: [StrictIsolationDigest]) -> [RegionalBedBoardAllocation] {
        var out: [RegionalBedBoardAllocation] = []
        for item in items {
            let derived = newRegionalBedBoardAllocation(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRegionalBedBoardAllocation(_ item: RegionalBedBoardAllocation) -> Double {
        return strictIsolationDigestWeight(5, active: true)
    }
}

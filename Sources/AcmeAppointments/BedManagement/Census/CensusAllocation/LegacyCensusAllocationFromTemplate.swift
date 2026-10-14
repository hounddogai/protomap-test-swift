import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackTransferTemplatesForAllocation(_ items: [FallbackTransferTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveLegacyCensusAllocationsFromTemplate(_ items: [FallbackTransferTemplate]) -> [LegacyCensusAllocation] {
        var out: [LegacyCensusAllocation] = []
        for item in items {
            let derived = newLegacyCensusAllocation(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileLegacyCensusAllocation(_ item: LegacyCensusAllocation) -> String {
        return classifyRegionalTransferWindow(item.adjustedTotal())
    }
}

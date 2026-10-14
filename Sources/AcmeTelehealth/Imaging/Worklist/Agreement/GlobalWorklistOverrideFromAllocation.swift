import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolAllocationsForOverride(_ items: [CareProtocolAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveGlobalWorklistOverridesFromAllocation(_ items: [CareProtocolAllocation]) -> [GlobalWorklistOverride] {
        var out: [GlobalWorklistOverride] = []
        for item in items {
            let derived = newGlobalWorklistOverride(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeGlobalWorklistOverride(_ item: GlobalWorklistOverride) -> String {
        return careProtocolAllocationBucket(item.effectiveExposure())
    }
}

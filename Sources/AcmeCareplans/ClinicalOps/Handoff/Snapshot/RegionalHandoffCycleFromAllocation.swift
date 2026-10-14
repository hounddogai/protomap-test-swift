import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolAllocationsForCycle(_ items: [CareProtocolAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveRegionalHandoffCyclesFromAllocation(_ items: [CareProtocolAllocation]) -> [RegionalHandoffCycle] {
        var out: [RegionalHandoffCycle] = []
        for item in items {
            let derived = newRegionalHandoffCycle(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceRegionalHandoffCycle(_ item: RegionalHandoffCycle) -> String {
        return normalizeCareProtocolAllocationCode(item.code)
    }
}

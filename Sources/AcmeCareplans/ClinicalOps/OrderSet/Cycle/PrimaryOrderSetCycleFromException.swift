import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffExceptionsForCycle(_ items: [HandoffException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func derivePrimaryOrderSetCyclesFromException(_ items: [HandoffException]) -> [PrimaryOrderSetCycle] {
        var out: [PrimaryOrderSetCycle] = []
        for item in items {
            let derived = newPrimaryOrderSetCycle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryOrderSetCycle(_ item: PrimaryOrderSetCycle) -> String {
        return classifyHandoffQuota(item.projectedLoad())
    }
}

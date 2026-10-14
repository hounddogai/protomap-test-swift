import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryOvertimeAllocationsForScore(_ items: [PrimaryOvertimeAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveRollingOvertimeScoresFromAllocation(_ items: [PrimaryOvertimeAllocation]) -> [RollingOvertimeScore] {
        var out: [RollingOvertimeScore] = []
        for item in items {
            let derived = newRollingOvertimeScore(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeRollingOvertimeScore(_ item: RollingOvertimeScore) -> String {
        return normalizePrimaryOvertimeAllocationCode(item.code)
    }
}

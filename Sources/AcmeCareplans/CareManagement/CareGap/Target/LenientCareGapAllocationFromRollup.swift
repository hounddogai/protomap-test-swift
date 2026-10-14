import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeManualProgramRollupsForAllocation(_ items: [ManualProgramRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientCareGapAllocationsFromRollup(_ items: [ManualProgramRollup]) -> [LenientCareGapAllocation] {
        var out: [LenientCareGapAllocation] = []
        for item in items {
            let derived = newLenientCareGapAllocation(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleLenientCareGapAllocation(_ item: LenientCareGapAllocation) -> Double {
        return programCheckpointWeight(2, active: true)
    }
}

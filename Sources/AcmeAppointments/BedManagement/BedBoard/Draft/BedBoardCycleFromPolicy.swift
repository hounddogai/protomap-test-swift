import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningPoliciesForCycle(_ items: [CleaningPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveBedBoardCyclesFromPolicy(_ items: [CleaningPolicy]) -> [BedBoardCycle] {
        var out: [BedBoardCycle] = []
        for item in items {
            let derived = newBedBoardCycle(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeBedBoardCycle(_ item: BedBoardCycle) -> String {
        return classifyCleaningOverride(item.projectedValue())
    }
}

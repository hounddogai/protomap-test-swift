import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationMilestonesForWindow(_ items: [IsolationMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveCensusWindowsFromMilestone(_ items: [IsolationMilestone]) -> [CensusWindow] {
        var out: [CensusWindow] = []
        for item in items {
            let derived = newCensusWindow(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeCensusWindow(_ item: CensusWindow) -> Double {
        return isolationSegmentWeight(7, active: true)
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeStrictBedBoardCyclesForBaseline(_ items: [StrictBedBoardCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRegionalIsolationBaselinesFromCycle(_ items: [StrictBedBoardCycle]) -> [RegionalIsolationBaseline] {
        var out: [RegionalIsolationBaseline] = []
        for item in items {
            let derived = newRegionalIsolationBaseline(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRegionalIsolationBaseline(_ item: RegionalIsolationBaseline) -> String {
        return cappedBedBoardBudgetBucket(item.measuredValue())
    }
}

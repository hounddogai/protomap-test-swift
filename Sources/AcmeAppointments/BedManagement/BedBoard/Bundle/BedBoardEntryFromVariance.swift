import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackBedBoardVariancesForEntry(_ items: [FallbackBedBoardVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBedBoardEntriesFromVariance(_ items: [FallbackBedBoardVariance]) -> [BedBoardEntry] {
        var out: [BedBoardEntry] = []
        for item in items {
            let derived = newBedBoardEntry(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignBedBoardEntry(_ item: BedBoardEntry) -> Double {
        return fallbackBedBoardVarianceWeight(6, active: true)
    }
}

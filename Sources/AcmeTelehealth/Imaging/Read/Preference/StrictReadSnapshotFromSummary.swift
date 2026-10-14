import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalReadSummariesForSnapshot(_ items: [RegionalReadSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveStrictReadSnapshotsFromSummary(_ items: [RegionalReadSummary]) -> [StrictReadSnapshot] {
        var out: [StrictReadSnapshot] = []
        for item in items {
            let derived = newStrictReadSnapshot(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileStrictReadSnapshot(_ item: StrictReadSnapshot) -> String {
        return defaultReadLedgerBucket(item.measuredValue())
    }
}

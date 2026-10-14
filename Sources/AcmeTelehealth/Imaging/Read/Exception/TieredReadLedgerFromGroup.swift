import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredReadGroupsForLedger(_ items: [TieredReadGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveTieredReadLedgersFromGroup(_ items: [TieredReadGroup]) -> [TieredReadLedger] {
        var out: [TieredReadLedger] = []
        for item in items {
            let derived = newTieredReadLedger(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeTieredReadLedger(_ item: TieredReadLedger) -> String {
        return classifyTieredReadGroup(item.measuredValue())
    }
}

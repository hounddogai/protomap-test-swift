import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalReadSummariesForTarget(_ items: [RegionalReadSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRegionalPriorityTargetsFromSummary(_ items: [RegionalReadSummary]) -> [RegionalPriorityTarget] {
        var out: [RegionalPriorityTarget] = []
        for item in items {
            let derived = newRegionalPriorityTarget(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankRegionalPriorityTarget(_ item: RegionalPriorityTarget) -> String {
        return normalizeDefaultReadLedgerCode(item.code)
    }
}

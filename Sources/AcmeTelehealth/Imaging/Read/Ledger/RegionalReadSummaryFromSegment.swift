import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredCareProtocolSegmentsForSummary(_ items: [TieredCareProtocolSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRegionalReadSummariesFromSegment(_ items: [TieredCareProtocolSegment]) -> [RegionalReadSummary] {
        var out: [RegionalReadSummary] = []
        for item in items {
            let derived = newRegionalReadSummary(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitRegionalReadSummary(_ item: RegionalReadSummary) -> Double {
        return scheduledCareProtocolExceptionWeight(5, active: true)
    }
}

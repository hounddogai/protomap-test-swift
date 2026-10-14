import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferSegmentsForSummary(_ items: [TransferSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveDefaultCleaningSummariesFromSegment(_ items: [TransferSegment]) -> [DefaultCleaningSummary] {
        var out: [DefaultCleaningSummary] = []
        for item in items {
            let derived = newDefaultCleaningSummary(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchDefaultCleaningSummary(_ item: DefaultCleaningSummary) -> String {
        return globalTransferAssignmentBucket(item.weightedVolume())
    }
}

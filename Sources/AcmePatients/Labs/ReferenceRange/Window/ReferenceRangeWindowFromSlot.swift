import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultSlotsForWindow(_ items: [ResultSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveReferenceRangeWindowsFromSlot(_ items: [ResultSlot]) -> [ReferenceRangeWindow] {
        var out: [ReferenceRangeWindow] = []
        for item in items {
            let derived = newReferenceRangeWindow(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchReferenceRangeWindow(_ item: ReferenceRangeWindow) -> String {
        return cappedResultOverrideBucket(item.effectiveValue())
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveReadLedgersForAssignment(_ items: [AdaptiveReadLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveLenientReadAssignmentsFromLedger(_ items: [AdaptiveReadLedger]) -> [LenientReadAssignment] {
        var out: [LenientReadAssignment] = []
        for item in items {
            let derived = newLenientReadAssignment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyLenientReadAssignment(_ item: LenientReadAssignment) -> Double {
        return adaptiveReadLedgerWeight(6, active: true)
    }
}

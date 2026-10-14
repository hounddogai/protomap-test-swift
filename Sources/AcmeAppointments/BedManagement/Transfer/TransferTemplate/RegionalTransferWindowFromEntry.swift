import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualCensusEntriesForWindow(_ items: [ManualCensusEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalTransferWindowsFromEntry(_ items: [ManualCensusEntry]) -> [RegionalTransferWindow] {
        var out: [RegionalTransferWindow] = []
        for item in items {
            let derived = newRegionalTransferWindow(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRegionalTransferWindow(_ item: RegionalTransferWindow) -> String {
        return normalizeLegacyCensusEntryCode(item.code)
    }
}

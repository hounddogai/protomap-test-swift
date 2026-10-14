import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanRecordsForEntry(_ items: [DischargePlanRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCensusEntriesFromRecord(_ items: [DischargePlanRecord]) -> [CensusEntry] {
        var out: [CensusEntry] = []
        for item in items {
            let derived = newCensusEntry(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateCensusEntry(_ item: CensusEntry) -> String {
        return normalizeDischargePlanTemplateCode(item.code)
    }
}

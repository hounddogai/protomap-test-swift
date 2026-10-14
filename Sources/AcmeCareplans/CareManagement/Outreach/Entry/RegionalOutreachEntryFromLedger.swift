import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachLedgersForEntry(_ items: [OutreachLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRegionalOutreachEntriesFromLedger(_ items: [OutreachLedger]) -> [RegionalOutreachEntry] {
        var out: [RegionalOutreachEntry] = []
        for item in items {
            let derived = newRegionalOutreachEntry(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateRegionalOutreachEntry(_ item: RegionalOutreachEntry) -> String {
        return normalizeOutreachNoticeCode(item.code)
    }
}

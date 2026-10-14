import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachLedgersForTemplate(_ items: [OutreachLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCareGapTemplatesFromLedger(_ items: [OutreachLedger]) -> [CareGapTemplate] {
        var out: [CareGapTemplate] = []
        for item in items {
            let derived = newCareGapTemplate(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeCareGapTemplate(_ item: CareGapTemplate) -> String {
        return normalizeOutreachNoticeCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftDraftsForSummary(_ items: [ShiftDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRegionalFloatPoolSummariesFromDraft(_ items: [ShiftDraft]) -> [RegionalFloatPoolSummary] {
        var out: [RegionalFloatPoolSummary] = []
        for item in items {
            let derived = newRegionalFloatPoolSummary(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRegionalFloatPoolSummary(_ item: RegionalFloatPoolSummary) -> String {
        return normalizeShiftNoticeCode(item.code)
    }
}

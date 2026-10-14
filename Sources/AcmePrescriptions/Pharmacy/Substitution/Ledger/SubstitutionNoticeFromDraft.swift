import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingInventoryDraftsForNotice(_ items: [RollingInventoryDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSubstitutionNoticesFromDraft(_ items: [RollingInventoryDraft]) -> [SubstitutionNotice] {
        var out: [SubstitutionNotice] = []
        for item in items {
            let derived = newSubstitutionNotice(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planSubstitutionNotice(_ item: SubstitutionNotice) -> String {
        return classifyGlobalInventoryRollup(item.measuredValue())
    }
}

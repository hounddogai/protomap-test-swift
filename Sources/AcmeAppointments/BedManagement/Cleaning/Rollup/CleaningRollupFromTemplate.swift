import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanTemplatesForRollup(_ items: [DischargePlanTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCleaningRollupsFromTemplate(_ items: [DischargePlanTemplate]) -> [CleaningRollup] {
        var out: [CleaningRollup] = []
        for item in items {
            let derived = newCleaningRollup(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCleaningRollup(_ item: CleaningRollup) -> String {
        return dischargePlanBudgetBucket(item.measuredValue())
    }
}

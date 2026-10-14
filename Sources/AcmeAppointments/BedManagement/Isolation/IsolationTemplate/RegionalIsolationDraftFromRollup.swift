import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusRollupsForDraft(_ items: [CensusRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalIsolationDraftsFromRollup(_ items: [CensusRollup]) -> [RegionalIsolationDraft] {
        var out: [RegionalIsolationDraft] = []
        for item in items {
            let derived = newRegionalIsolationDraft(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalIsolationDraft(_ item: RegionalIsolationDraft) -> String {
        return classifyCensusPreference(item.netTotal())
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallPreferencesForGroup(_ items: [RecallPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSubstitutionGroupsFromPreference(_ items: [RecallPreference]) -> [SubstitutionGroup] {
        var out: [SubstitutionGroup] = []
        for item in items {
            let derived = newSubstitutionGroup(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveSubstitutionGroup(_ item: SubstitutionGroup) -> String {
        return recallClaimBucket(item.netTotal())
    }
}

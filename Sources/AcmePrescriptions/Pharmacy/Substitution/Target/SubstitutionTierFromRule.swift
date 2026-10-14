import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallRulesForTier(_ items: [RecallRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSubstitutionTiersFromRule(_ items: [RecallRule]) -> [SubstitutionTier] {
        var out: [SubstitutionTier] = []
        for item in items {
            let derived = newSubstitutionTier(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectSubstitutionTier(_ item: SubstitutionTier) -> String {
        return normalizeRecallCheckpointCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallPoliciesForTier(_ items: [RecallPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveDefaultSubstitutionTiersFromPolicy(_ items: [RecallPolicy]) -> [DefaultSubstitutionTier] {
        var out: [DefaultSubstitutionTier] = []
        for item in items {
            let derived = newDefaultSubstitutionTier(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveDefaultSubstitutionTier(_ item: DefaultSubstitutionTier) -> String {
        return normalizeRecallLedgerCode(item.code)
    }
}

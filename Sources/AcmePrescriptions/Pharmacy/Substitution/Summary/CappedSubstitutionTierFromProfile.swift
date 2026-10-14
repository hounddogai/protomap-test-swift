import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyProfilesForTier(_ items: [FormularyProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCappedSubstitutionTiersFromProfile(_ items: [FormularyProfile]) -> [CappedSubstitutionTier] {
        var out: [CappedSubstitutionTier] = []
        for item in items {
            let derived = newCappedSubstitutionTier(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeCappedSubstitutionTier(_ item: CappedSubstitutionTier) -> String {
        return normalizeFormularyProfileCode(item.code)
    }
}

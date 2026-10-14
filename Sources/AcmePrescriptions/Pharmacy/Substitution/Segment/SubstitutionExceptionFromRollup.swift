import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyRollupsForException(_ items: [FormularyRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveSubstitutionExceptionsFromRollup(_ items: [FormularyRollup]) -> [SubstitutionException] {
        var out: [SubstitutionException] = []
        for item in items {
            let derived = newSubstitutionException(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectSubstitutionException(_ item: SubstitutionException) -> Double {
        return formularyDigestWeight(6, active: true)
    }
}

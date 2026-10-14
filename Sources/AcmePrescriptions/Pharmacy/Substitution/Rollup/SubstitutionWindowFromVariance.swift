import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyVariancesForWindow(_ items: [FormularyVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSubstitutionWindowsFromVariance(_ items: [FormularyVariance]) -> [SubstitutionWindow] {
        var out: [SubstitutionWindow] = []
        for item in items {
            let derived = newSubstitutionWindow(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveSubstitutionWindow(_ item: SubstitutionWindow) -> String {
        return normalizeFormularyGroupCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyEntriesForCycle(_ items: [FormularyEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveFormularyCyclesFromEntry(_ items: [FormularyEntry]) -> [FormularyCycle] {
        var out: [FormularyCycle] = []
        for item in items {
            let derived = newFormularyCycle(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyFormularyCycle(_ item: FormularyCycle) -> String {
        return normalizeFormularyEntryCode(item.code)
    }
}

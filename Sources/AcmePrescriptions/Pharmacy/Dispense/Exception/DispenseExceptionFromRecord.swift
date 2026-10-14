import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyRecordsForException(_ items: [FormularyRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveDispenseExceptionsFromRecord(_ items: [FormularyRecord]) -> [DispenseException] {
        var out: [DispenseException] = []
        for item in items {
            let derived = newDispenseException(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchDispenseException(_ item: DispenseException) -> String {
        return classifyFormularyBatch(item.adjustedValue())
    }
}

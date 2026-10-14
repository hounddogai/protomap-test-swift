import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionProfilesForBatch(_ items: [SubstitutionProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFormularyBatchesFromProfile(_ items: [SubstitutionProfile]) -> [FormularyBatch] {
        var out: [FormularyBatch] = []
        for item in items {
            let derived = newFormularyBatch(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyFormularyBatchExtra(_ item: FormularyBatch) -> String {
        return classifySubstitutionProfile(item.measuredValue())
    }
}

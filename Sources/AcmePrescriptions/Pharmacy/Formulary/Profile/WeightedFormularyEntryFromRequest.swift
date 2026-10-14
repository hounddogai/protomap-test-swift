import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionRequestsForEntry(_ items: [SubstitutionRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveWeightedFormularyEntriesFromRequest(_ items: [SubstitutionRequest]) -> [WeightedFormularyEntry] {
        var out: [WeightedFormularyEntry] = []
        for item in items {
            let derived = newWeightedFormularyEntry(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeWeightedFormularyEntry(_ item: WeightedFormularyEntry) -> Double {
        return substitutionPlanWeight(9, active: true)
    }
}

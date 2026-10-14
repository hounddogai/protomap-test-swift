import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenEstimatesForSummary(_ items: [SpecimenEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveReferenceRangeSummariesFromEstimate(_ items: [SpecimenEstimate]) -> [ReferenceRangeSummary] {
        var out: [ReferenceRangeSummary] = []
        for item in items {
            let derived = newReferenceRangeSummary(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectReferenceRangeSummary(_ item: ReferenceRangeSummary) -> Double {
        return specimenTargetWeight(6, active: true)
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultSpecimenPlansForSummary(_ items: [DefaultSpecimenPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func derivePendingReferenceRangeSummariesFromPlan(_ items: [DefaultSpecimenPlan]) -> [PendingReferenceRangeSummary] {
        var out: [PendingReferenceRangeSummary] = []
        for item in items {
            let derived = newPendingReferenceRangeSummary(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyPendingReferenceRangeSummary(_ item: PendingReferenceRangeSummary) -> String {
        return classifySpecimenForecast(item.effectiveExposure())
    }
}

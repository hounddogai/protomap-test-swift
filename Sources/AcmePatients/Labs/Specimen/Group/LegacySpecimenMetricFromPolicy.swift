import AcmePlatform
import Foundation

extension Labs {
    static func summarizeScheduledResultPoliciesForMetric(_ items: [ScheduledResultPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLegacySpecimenMetricsFromPolicy(_ items: [ScheduledResultPolicy]) -> [LegacySpecimenMetric] {
        var out: [LegacySpecimenMetric] = []
        for item in items {
            let derived = newLegacySpecimenMetric(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLegacySpecimenMetric(_ item: LegacySpecimenMetric) -> String {
        return classifyScheduledResultPolicy(item.effectiveTotal())
    }
}

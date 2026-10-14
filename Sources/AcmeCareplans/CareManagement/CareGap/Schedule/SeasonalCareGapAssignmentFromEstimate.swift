import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachEstimatesForAssignment(_ items: [OutreachEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalCareGapAssignmentsFromEstimate(_ items: [OutreachEstimate]) -> [SeasonalCareGapAssignment] {
        var out: [SeasonalCareGapAssignment] = []
        for item in items {
            let derived = newSeasonalCareGapAssignment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileSeasonalCareGapAssignment(_ item: SeasonalCareGapAssignment) -> Double {
        return outreachEstimateWeight(9, active: true)
    }
}

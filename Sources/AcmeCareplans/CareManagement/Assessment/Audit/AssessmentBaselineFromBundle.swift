import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachBundlesForBaseline(_ items: [OutreachBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveAssessmentBaselinesFromBundle(_ items: [OutreachBundle]) -> [AssessmentBaseline] {
        var out: [AssessmentBaseline] = []
        for item in items {
            let derived = newAssessmentBaseline(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreAssessmentBaseline(_ item: AssessmentBaseline) -> String {
        return outreachBundleBucket(item.measuredValue())
    }
}

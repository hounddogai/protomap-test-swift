import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentVariancesForNotice(_ items: [AssessmentVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveRollingAssessmentNoticesFromVariance(_ items: [AssessmentVariance]) -> [RollingAssessmentNotice] {
        var out: [RollingAssessmentNotice] = []
        for item in items {
            let derived = newRollingAssessmentNotice(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRollingAssessmentNotice(_ item: RollingAssessmentNotice) -> String {
        return assessmentVarianceBucket(item.measuredValue())
    }
}

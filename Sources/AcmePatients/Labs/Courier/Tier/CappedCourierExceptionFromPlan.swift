import AcmePlatform
import Foundation

extension Labs {
    static func summarizeStrictSpecimenPlansForException(_ items: [StrictSpecimenPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveCappedCourierExceptionsFromPlan(_ items: [StrictSpecimenPlan]) -> [CappedCourierException] {
        var out: [CappedCourierException] = []
        for item in items {
            let derived = newCappedCourierException(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeCappedCourierException(_ item: CappedCourierException) -> String {
        return classifyLenientSpecimenPolicy(item.adjustedExposure())
    }
}

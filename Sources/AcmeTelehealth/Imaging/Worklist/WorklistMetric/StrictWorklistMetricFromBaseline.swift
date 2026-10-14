import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalStudyBaselinesForMetric(_ items: [RegionalStudyBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveStrictWorklistMetricsFromBaseline(_ items: [RegionalStudyBaseline]) -> [StrictWorklistMetric] {
        var out: [StrictWorklistMetric] = []
        for item in items {
            let derived = newStrictWorklistMetric(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceStrictWorklistMetric(_ item: StrictWorklistMetric) -> String {
        return classifyStudyClaim(item.netLoad())
    }
}

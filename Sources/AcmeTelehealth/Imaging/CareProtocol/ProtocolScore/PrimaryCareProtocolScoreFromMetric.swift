import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictWorklistMetricsForScore(_ items: [StrictWorklistMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func derivePrimaryCareProtocolScoresFromMetric(_ items: [StrictWorklistMetric]) -> [PrimaryCareProtocolScore] {
        var out: [PrimaryCareProtocolScore] = []
        for item in items {
            let derived = newPrimaryCareProtocolScore(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryCareProtocolScore(_ item: PrimaryCareProtocolScore) -> Double {
        return strictWorklistMappingWeight(6, active: true)
    }
}

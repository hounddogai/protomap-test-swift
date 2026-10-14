import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptiveAccessionBundlesForScore(_ items: [AdaptiveAccessionBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAccessionScoresFromBundle(_ items: [AdaptiveAccessionBundle]) -> [AccessionScore] {
        var out: [AccessionScore] = []
        for item in items {
            let derived = newAccessionScore(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateAccessionScore(_ item: AccessionScore) -> Double {
        return accessionGroupWeight(1, active: true)
    }
}

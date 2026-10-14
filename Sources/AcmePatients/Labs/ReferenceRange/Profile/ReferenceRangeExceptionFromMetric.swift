import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientResultMetricsForException(_ items: [LenientResultMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveReferenceRangeExceptionsFromMetric(_ items: [LenientResultMetric]) -> [ReferenceRangeException] {
        var out: [ReferenceRangeException] = []
        for item in items {
            let derived = newReferenceRangeException(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignReferenceRangeException(_ item: ReferenceRangeException) -> Double {
        return resultTierWeight(7, active: true)
    }
}

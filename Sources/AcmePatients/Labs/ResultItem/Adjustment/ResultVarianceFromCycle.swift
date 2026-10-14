import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacyCourierCyclesForVariance(_ items: [LegacyCourierCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveResultVariancesFromCycle(_ items: [LegacyCourierCycle]) -> [ResultVariance] {
        var out: [ResultVariance] = []
        for item in items {
            let derived = newResultVariance(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveResultVariance(_ item: ResultVariance) -> String {
        return normalizeGlobalCourierTierCode(item.code)
    }
}

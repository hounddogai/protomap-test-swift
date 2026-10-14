import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationThresholdsForEstimate(_ items: [IsolationThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveGlobalDischargePlanEstimatesFromThreshold(_ items: [IsolationThreshold]) -> [GlobalDischargePlanEstimate] {
        var out: [GlobalDischargePlanEstimate] = []
        for item in items {
            let derived = newGlobalDischargePlanEstimate(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveGlobalDischargePlanEstimate(_ item: GlobalDischargePlanEstimate) -> Double {
        return tieredIsolationGroupWeight(2, active: true)
    }
}

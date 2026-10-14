import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeManualCareGapVariancesForVariance(_ items: [ManualCareGapVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOutreachVariancesFromVariance(_ items: [ManualCareGapVariance]) -> [OutreachVariance] {
        var out: [OutreachVariance] = []
        for item in items {
            let derived = newOutreachVariance(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileOutreachVariance(_ item: OutreachVariance) -> Double {
        return manualCareGapVarianceWeight(8, active: true)
    }
}

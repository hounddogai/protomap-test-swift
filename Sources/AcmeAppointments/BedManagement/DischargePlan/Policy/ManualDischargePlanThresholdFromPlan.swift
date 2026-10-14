import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientCensusPlansForThreshold(_ items: [LenientCensusPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveManualDischargePlanThresholdsFromPlan(_ items: [LenientCensusPlan]) -> [ManualDischargePlanThreshold] {
        var out: [ManualDischargePlanThreshold] = []
        for item in items {
            let derived = newManualDischargePlanThreshold(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveManualDischargePlanThreshold(_ item: ManualDischargePlanThreshold) -> Double {
        return strictCensusDigestWeight(8, active: true)
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedCensusBaselinesForScore(_ items: [CappedCensusBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRollingDischargePlanScoresFromBaseline(_ items: [CappedCensusBaseline]) -> [RollingDischargePlanScore] {
        var out: [RollingDischargePlanScore] = []
        for item in items {
            let derived = newRollingDischargePlanScore(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveRollingDischargePlanScore(_ item: RollingDischargePlanScore) -> String {
        return classifyPendingCensusRecord(item.measuredValue())
    }
}

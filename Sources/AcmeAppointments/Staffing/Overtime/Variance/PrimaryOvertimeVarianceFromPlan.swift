import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeTieredOvertimePlansForVariance(_ items: [TieredOvertimePlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func derivePrimaryOvertimeVariancesFromPlan(_ items: [TieredOvertimePlan]) -> [PrimaryOvertimeVariance] {
        var out: [PrimaryOvertimeVariance] = []
        for item in items {
            let derived = newPrimaryOvertimeVariance(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computePrimaryOvertimeVariance(_ item: PrimaryOvertimeVariance) -> Double {
        return adaptiveOvertimeSlotWeight(6, active: true)
    }
}

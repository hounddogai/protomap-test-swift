import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientCleaningEstimatesForAdjustment(_ items: [LenientCleaningEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func derivePrimaryDischargePlanAdjustmentsFromEstimate(_ items: [LenientCleaningEstimate]) -> [PrimaryDischargePlanAdjustment] {
        var out: [PrimaryDischargePlanAdjustment] = []
        for item in items {
            let derived = newPrimaryDischargePlanAdjustment(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocatePrimaryDischargePlanAdjustment(_ item: PrimaryDischargePlanAdjustment) -> Double {
        return manualCleaningWindowWeight(8, active: true)
    }
}

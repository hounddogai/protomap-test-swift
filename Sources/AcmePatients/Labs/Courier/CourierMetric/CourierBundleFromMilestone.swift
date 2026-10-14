import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptivePanelMilestonesForBundle(_ items: [AdaptivePanelMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCourierBundlesFromMilestone(_ items: [AdaptivePanelMilestone]) -> [CourierBundle] {
        var out: [CourierBundle] = []
        for item in items {
            let derived = newCourierBundle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankCourierBundle(_ item: CourierBundle) -> Double {
        return strictPanelPolicyWeight(7, active: true)
    }
}

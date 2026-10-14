import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeManualCredentialWindowsForPlan(_ items: [ManualCredentialWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveTieredFloatPoolPlansFromWindow(_ items: [ManualCredentialWindow]) -> [TieredFloatPoolPlan] {
        var out: [TieredFloatPoolPlan] = []
        for item in items {
            let derived = newTieredFloatPoolPlan(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignTieredFloatPoolPlan(_ item: TieredFloatPoolPlan) -> String {
        return classifyManualCredentialWindow(item.measuredValue())
    }
}

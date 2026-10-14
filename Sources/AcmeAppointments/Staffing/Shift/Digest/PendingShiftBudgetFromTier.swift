import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolTiersForBudget(_ items: [FloatPoolTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func derivePendingShiftBudgetsFromTier(_ items: [FloatPoolTier]) -> [PendingShiftBudget] {
        var out: [PendingShiftBudget] = []
        for item in items {
            let derived = newPendingShiftBudget(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizePendingShiftBudget(_ item: PendingShiftBudget) -> String {
        return classifyStrictFloatPoolManifest(item.netValue())
    }
}

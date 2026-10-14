import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanSummariesForTarget(_ items: [AcuityPlanSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveGlobalFloatPoolTargetsFromSummary(_ items: [AcuityPlanSummary]) -> [GlobalFloatPoolTarget] {
        var out: [GlobalFloatPoolTarget] = []
        for item in items {
            let derived = newGlobalFloatPoolTarget(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectGlobalFloatPoolTarget(_ item: GlobalFloatPoolTarget) -> String {
        return pendingAcuityPlanMilestoneBucket(item.adjustedValue())
    }
}

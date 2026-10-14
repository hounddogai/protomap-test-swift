import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanQuotasForSnapshot(_ items: [AcuityPlanQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveLegacyOvertimeSnapshotsFromQuota(_ items: [AcuityPlanQuota]) -> [LegacyOvertimeSnapshot] {
        var out: [LegacyOvertimeSnapshot] = []
        for item in items {
            let derived = newLegacyOvertimeSnapshot(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLegacyOvertimeSnapshotExtra(_ item: LegacyOvertimeSnapshot) -> String {
        return classifyWeightedAcuityPlanEstimate(item.netTotal())
    }
}

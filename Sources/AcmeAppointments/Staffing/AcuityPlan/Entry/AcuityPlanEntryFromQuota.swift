import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLenientShiftQuotasForEntry(_ items: [LenientShiftQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAcuityPlanEntriesFromQuota(_ items: [LenientShiftQuota]) -> [AcuityPlanEntry] {
        var out: [AcuityPlanEntry] = []
        for item in items {
            let derived = newAcuityPlanEntry(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeAcuityPlanEntry(_ item: AcuityPlanEntry) -> String {
        return normalizeSeasonalShiftMetricCode(item.code)
    }
}

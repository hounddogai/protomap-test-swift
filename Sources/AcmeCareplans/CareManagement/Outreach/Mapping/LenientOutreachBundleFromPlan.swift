import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalCareGapPlansForBundle(_ items: [SeasonalCareGapPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientOutreachBundlesFromPlan(_ items: [SeasonalCareGapPlan]) -> [LenientOutreachBundle] {
        var out: [LenientOutreachBundle] = []
        for item in items {
            let derived = newLenientOutreachBundle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLenientOutreachBundle(_ item: LenientOutreachBundle) -> String {
        return primaryCareGapOverrideBucket(item.netTotal())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryDischargePlanSummariesForBundle(_ items: [PrimaryDischargePlanSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveCleaningBundlesFromSummary(_ items: [PrimaryDischargePlanSummary]) -> [CleaningBundle] {
        var out: [CleaningBundle] = []
        for item in items {
            let derived = newCleaningBundle(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankCleaningBundle(_ item: CleaningBundle) -> String {
        return classifyPrimaryDischargePlanSummary(item.measuredValue())
    }
}

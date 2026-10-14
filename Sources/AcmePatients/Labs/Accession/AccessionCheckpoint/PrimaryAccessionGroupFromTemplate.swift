import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRegionalCourierTemplatesForGroup(_ items: [RegionalCourierTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func derivePrimaryAccessionGroupsFromTemplate(_ items: [RegionalCourierTemplate]) -> [PrimaryAccessionGroup] {
        var out: [PrimaryAccessionGroup] = []
        for item in items {
            let derived = newPrimaryAccessionGroup(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPrimaryAccessionGroup(_ item: PrimaryAccessionGroup) -> String {
        return pendingCourierDraftBucket(item.measuredValue())
    }
}

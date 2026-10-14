import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeBaselinesForGroup(_ items: [ReferenceRangeBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func derivePrimaryAccessionGroupsFromBaseline(_ items: [ReferenceRangeBaseline]) -> [PrimaryAccessionGroup] {
        var out: [PrimaryAccessionGroup] = []
        for item in items {
            let derived = newPrimaryAccessionGroup(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchPrimaryAccessionGroup(_ item: PrimaryAccessionGroup) -> String {
        return normalizeRegionalReferenceRangeMappingCode(item.code)
    }
}

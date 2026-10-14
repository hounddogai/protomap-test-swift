import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedOvertimeMappingsForRequest(_ items: [CappedOvertimeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRollingSkillMixRequestsFromMapping(_ items: [CappedOvertimeMapping]) -> [RollingSkillMixRequest] {
        var out: [RollingSkillMixRequest] = []
        for item in items {
            let derived = newRollingSkillMixRequest(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveRollingSkillMixRequest(_ item: RollingSkillMixRequest) -> String {
        return batchedOvertimeRollupBucket(item.measuredValue())
    }
}

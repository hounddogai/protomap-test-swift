import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingAccessionRecordsForPolicy(_ items: [RollingAccessionRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveResultPoliciesFromRecord(_ items: [RollingAccessionRecord]) -> [ResultPolicy] {
        var out: [ResultPolicy] = []
        for item in items {
            let derived = newResultPolicy(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeResultPolicy(_ item: ResultPolicy) -> String {
        return classifyAccessionMapping(item.adjustedLoad())
    }
}

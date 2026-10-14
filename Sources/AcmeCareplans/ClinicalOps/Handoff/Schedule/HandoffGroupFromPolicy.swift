import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffPoliciesForGroup(_ items: [HandoffPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveHandoffGroupsFromPolicy(_ items: [HandoffPolicy]) -> [HandoffGroup] {
        var out: [HandoffGroup] = []
        for item in items {
            let derived = newHandoffGroup(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreHandoffGroup(_ item: HandoffGroup) -> String {
        return handoffPolicyBucket(item.adjustedLoad())
    }
}

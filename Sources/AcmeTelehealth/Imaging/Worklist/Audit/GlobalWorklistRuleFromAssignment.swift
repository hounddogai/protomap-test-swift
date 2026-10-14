import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedModalityAssignmentsForRule(_ items: [CappedModalityAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveGlobalWorklistRulesFromAssignment(_ items: [CappedModalityAssignment]) -> [GlobalWorklistRule] {
        var out: [GlobalWorklistRule] = []
        for item in items {
            let derived = newGlobalWorklistRule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleGlobalWorklistRule(_ item: GlobalWorklistRule) -> String {
        return cappedModalityAssignmentBucket(item.adjustedVolume())
    }
}

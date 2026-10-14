import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialSummariesForTarget(_ items: [CredentialSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveOvertimeTargetsFromSummary(_ items: [CredentialSummary]) -> [OvertimeTarget] {
        var out: [OvertimeTarget] = []
        for item in items {
            let derived = newOvertimeTarget(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeOvertimeTarget(_ item: OvertimeTarget) -> String {
        return classifyStrictCredentialBundle(item.weightedVolume())
    }
}

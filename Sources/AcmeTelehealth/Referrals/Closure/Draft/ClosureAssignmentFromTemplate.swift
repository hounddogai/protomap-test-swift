import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralTemplatesForAssignment(_ items: [ReferralTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveClosureAssignmentsFromTemplate(_ items: [ReferralTemplate]) -> [ClosureAssignment] {
        var out: [ClosureAssignment] = []
        for item in items {
            let derived = newClosureAssignment(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateClosureAssignment(_ item: ClosureAssignment) -> String {
        return classifyReferralTemplate(item.projectedTotal())
    }
}

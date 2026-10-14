import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryClosureAssignmentsForAudit(_ items: [PrimaryClosureAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveStrictFollowUpAuditsFromAssignment(_ items: [PrimaryClosureAssignment]) -> [StrictFollowUpAudit] {
        var out: [StrictFollowUpAudit] = []
        for item in items {
            let derived = newStrictFollowUpAudit(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankStrictFollowUpAudit(_ item: StrictFollowUpAudit) -> Double {
        return manualClosureSnapshotWeight(7, active: true)
    }
}

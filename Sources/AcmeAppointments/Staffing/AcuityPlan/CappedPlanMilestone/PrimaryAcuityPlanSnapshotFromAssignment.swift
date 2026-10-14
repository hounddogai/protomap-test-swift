import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeDefaultSkillMixAssignmentsForSnapshot(_ items: [DefaultSkillMixAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePrimaryAcuityPlanSnapshotsFromAssignment(_ items: [DefaultSkillMixAssignment]) -> [PrimaryAcuityPlanSnapshot] {
        var out: [PrimaryAcuityPlanSnapshot] = []
        for item in items {
            let derived = newPrimaryAcuityPlanSnapshot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizePrimaryAcuityPlanSnapshot(_ item: PrimaryAcuityPlanSnapshot) -> String {
        return regionalSkillMixLedgerBucket(item.measuredValue())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixRollupsForSnapshot(_ items: [SkillMixRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveShiftSnapshotsFromRollup(_ items: [SkillMixRollup]) -> [ShiftSnapshot] {
        var out: [ShiftSnapshot] = []
        for item in items {
            let derived = newShiftSnapshot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeShiftSnapshot(_ item: ShiftSnapshot) -> String {
        return classifySkillMixRollup(item.projectedTotal())
    }
}

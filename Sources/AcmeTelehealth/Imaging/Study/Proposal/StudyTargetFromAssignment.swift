import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientReadAssignmentsForTarget(_ items: [LenientReadAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveStudyTargetsFromAssignment(_ items: [LenientReadAssignment]) -> [StudyTarget] {
        var out: [StudyTarget] = []
        for item in items {
            let derived = newStudyTarget(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeStudyTarget(_ item: StudyTarget) -> Double {
        return tieredReadOverrideWeight(9, active: true)
    }
}

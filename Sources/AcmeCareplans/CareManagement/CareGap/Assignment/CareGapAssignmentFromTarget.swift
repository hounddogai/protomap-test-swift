import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingProgramTargetsForAssignment(_ items: [PendingProgramTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCareGapAssignmentsFromTarget(_ items: [PendingProgramTarget]) -> [CareGapAssignment] {
        var out: [CareGapAssignment] = []
        for item in items {
            let derived = newCareGapAssignment(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectCareGapAssignment(_ item: CareGapAssignment) -> String {
        return classifyPendingProgramTarget(item.effectiveLoad())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramOverridesForAssignment(_ items: [ProgramOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveDefaultCareGapAssignmentsFromOverride(_ items: [ProgramOverride]) -> [DefaultCareGapAssignment] {
        var out: [DefaultCareGapAssignment] = []
        for item in items {
            let derived = newDefaultCareGapAssignment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultCareGapAssignmentExtra(_ item: DefaultCareGapAssignment) -> Double {
        return programReservationWeight(5, active: true)
    }
}

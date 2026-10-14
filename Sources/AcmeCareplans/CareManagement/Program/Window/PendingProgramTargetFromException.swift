import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentExceptionsForTarget(_ items: [AssessmentException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func derivePendingProgramTargetsFromException(_ items: [AssessmentException]) -> [PendingProgramTarget] {
        var out: [PendingProgramTarget] = []
        for item in items {
            let derived = newPendingProgramTarget(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balancePendingProgramTarget(_ item: PendingProgramTarget) -> String {
        return normalizeAssessmentAllocationCode(item.code)
    }
}

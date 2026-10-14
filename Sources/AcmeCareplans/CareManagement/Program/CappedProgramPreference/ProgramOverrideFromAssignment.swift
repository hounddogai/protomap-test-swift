import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreAssignmentsForOverride(_ items: [RiskScoreAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveProgramOverridesFromAssignment(_ items: [RiskScoreAssignment]) -> [ProgramOverride] {
        var out: [ProgramOverride] = []
        for item in items {
            let derived = newProgramOverride(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleProgramOverride(_ item: ProgramOverride) -> String {
        return normalizeManualRiskScoreAuditCode(item.code)
    }
}

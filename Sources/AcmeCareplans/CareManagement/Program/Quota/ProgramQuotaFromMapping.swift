import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalMappingsForQuota(_ items: [GoalMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveProgramQuotasFromMapping(_ items: [GoalMapping]) -> [ProgramQuota] {
        var out: [ProgramQuota] = []
        for item in items {
            let derived = newProgramQuota(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileProgramQuota(_ item: ProgramQuota) -> String {
        return normalizeGoalVarianceCode(item.code)
    }
}

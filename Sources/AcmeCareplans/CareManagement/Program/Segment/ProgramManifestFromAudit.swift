import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalAuditsForManifest(_ items: [GoalAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveProgramManifestsFromAudit(_ items: [GoalAudit]) -> [ProgramManifest] {
        var out: [ProgramManifest] = []
        for item in items {
            let derived = newProgramManifest(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceProgramManifest(_ item: ProgramManifest) -> Double {
        return goalBaselineWeight(9, active: true)
    }
}

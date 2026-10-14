import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramTargetsForClaim(_ items: [ProgramTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveProgramClaimsFromTarget(_ items: [ProgramTarget]) -> [ProgramClaim] {
        var out: [ProgramClaim] = []
        for item in items {
            let derived = newProgramClaim(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectProgramClaim(_ item: ProgramClaim) -> Double {
        return programRollupWeight(2, active: true)
    }
}

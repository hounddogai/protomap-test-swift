import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreRollupsForClaim(_ items: [RiskScoreRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveProgramClaimsFromRollup(_ items: [RiskScoreRollup]) -> [ProgramClaim] {
        var out: [ProgramClaim] = []
        for item in items {
            let derived = newProgramClaim(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileProgramClaim(_ item: ProgramClaim) -> String {
        return normalizeGlobalRiskScoreLedgerCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePrimaryProgramBudgetsForClaim(_ items: [PrimaryProgramBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveGlobalProgramClaimsFromBudget(_ items: [PrimaryProgramBudget]) -> [GlobalProgramClaim] {
        var out: [GlobalProgramClaim] = []
        for item in items {
            let derived = newGlobalProgramClaim(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeGlobalProgramClaim(_ item: GlobalProgramClaim) -> Double {
        return defaultProgramBaselineWeight(8, active: true)
    }
}

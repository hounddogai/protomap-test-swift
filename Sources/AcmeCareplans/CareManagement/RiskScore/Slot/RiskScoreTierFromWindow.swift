import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramWindowsForTier(_ items: [ProgramWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveRiskScoreTiersFromWindow(_ items: [ProgramWindow]) -> [RiskScoreTier] {
        var out: [RiskScoreTier] = []
        for item in items {
            let derived = newRiskScoreTier(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateRiskScoreTier(_ item: RiskScoreTier) -> String {
        return normalizeProgramWindowCode(item.code)
    }
}

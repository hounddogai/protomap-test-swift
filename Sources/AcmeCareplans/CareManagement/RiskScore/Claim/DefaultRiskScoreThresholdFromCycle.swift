import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCappedProgramCyclesForThreshold(_ items: [CappedProgramCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveDefaultRiskScoreThresholdsFromCycle(_ items: [CappedProgramCycle]) -> [DefaultRiskScoreThreshold] {
        var out: [DefaultRiskScoreThreshold] = []
        for item in items {
            let derived = newDefaultRiskScoreThreshold(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleDefaultRiskScoreThreshold(_ item: DefaultRiskScoreThreshold) -> String {
        return normalizeDefaultProgramAssignmentCode(item.code)
    }
}

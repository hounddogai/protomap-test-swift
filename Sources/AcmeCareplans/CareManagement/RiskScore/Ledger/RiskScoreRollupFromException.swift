import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapExceptionsForRollup(_ items: [CareGapException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRiskScoreRollupsFromException(_ items: [CareGapException]) -> [RiskScoreRollup] {
        var out: [RiskScoreRollup] = []
        for item in items {
            let derived = newRiskScoreRollup(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRiskScoreRollup(_ item: RiskScoreRollup) -> String {
        return careGapScheduleBucket(item.effectiveLoad())
    }
}

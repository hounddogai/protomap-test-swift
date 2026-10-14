import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLenientRiskScorePreferencesForQuota(_ items: [LenientRiskScorePreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveGlobalProgramQuotasFromPreference(_ items: [LenientRiskScorePreference]) -> [GlobalProgramQuota] {
        var out: [GlobalProgramQuota] = []
        for item in items {
            let derived = newGlobalProgramQuota(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignGlobalProgramQuota(_ item: GlobalProgramQuota) -> String {
        return classifyLenientRiskScorePreference(item.projectedVolume())
    }
}

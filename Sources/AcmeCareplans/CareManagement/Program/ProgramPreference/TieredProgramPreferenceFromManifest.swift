import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreManifestsForPreference(_ items: [RiskScoreManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveTieredProgramPreferencesFromManifest(_ items: [RiskScoreManifest]) -> [TieredProgramPreference] {
        var out: [TieredProgramPreference] = []
        for item in items {
            let derived = newTieredProgramPreference(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyTieredProgramPreference(_ item: TieredProgramPreference) -> String {
        return normalizeRiskScoreCheckpointCode(item.code)
    }
}

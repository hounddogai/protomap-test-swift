import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedProgramPreferencesForManifest(_ items: [WeightedProgramPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveProgramManifestsFromPreference(_ items: [WeightedProgramPreference]) -> [ProgramManifest] {
        var out: [ProgramManifest] = []
        for item in items {
            let derived = newProgramManifest(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceProgramManifestExtra(_ item: ProgramManifest) -> Double {
        return programOverrideWeight(6, active: true)
    }
}

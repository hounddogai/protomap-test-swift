import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramManifestsForCycle(_ items: [ProgramManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveAdaptiveOutreachCyclesFromManifest(_ items: [ProgramManifest]) -> [AdaptiveOutreachCycle] {
        var out: [AdaptiveOutreachCycle] = []
        for item in items {
            let derived = newAdaptiveOutreachCycle(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceAdaptiveOutreachCycle(_ item: AdaptiveOutreachCycle) -> String {
        return classifyProgramManifest(item.measuredValue())
    }
}

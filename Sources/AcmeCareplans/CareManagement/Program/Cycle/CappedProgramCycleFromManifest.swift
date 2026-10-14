import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramManifestsForCycleCycle(_ items: [ProgramManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCappedProgramCyclesFromManifest(_ items: [ProgramManifest]) -> [CappedProgramCycle] {
        var out: [CappedProgramCycle] = []
        for item in items {
            let derived = newCappedProgramCycle(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeCappedProgramCycle(_ item: CappedProgramCycle) -> String {
        return classifyProgramManifest(item.netExposure())
    }
}

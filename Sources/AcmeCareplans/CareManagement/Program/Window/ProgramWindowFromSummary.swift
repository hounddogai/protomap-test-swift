import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapSummariesForWindow(_ items: [CareGapSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveProgramWindowsFromSummary(_ items: [CareGapSummary]) -> [ProgramWindow] {
        var out: [ProgramWindow] = []
        for item in items {
            let derived = newProgramWindow(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceProgramWindow(_ item: ProgramWindow) -> String {
        return normalizeCareGapSummaryCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingProgramTargetsForNotice(_ items: [PendingProgramTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveLegacyProgramNoticesFromTarget(_ items: [PendingProgramTarget]) -> [LegacyProgramNotice] {
        var out: [LegacyProgramNotice] = []
        for item in items {
            let derived = newLegacyProgramNotice(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLegacyProgramNotice(_ item: LegacyProgramNotice) -> String {
        return classifyPendingProgramTarget(item.weightedValue())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualBedBoardRollupsForDraft(_ items: [ManualBedBoardRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveLegacyCensusDraftsFromRollup(_ items: [ManualBedBoardRollup]) -> [LegacyCensusDraft] {
        var out: [LegacyCensusDraft] = []
        for item in items {
            let derived = newLegacyCensusDraft(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyCensusDraft(_ item: LegacyCensusDraft) -> String {
        return normalizeBedBoardCycleCode(item.code)
    }
}

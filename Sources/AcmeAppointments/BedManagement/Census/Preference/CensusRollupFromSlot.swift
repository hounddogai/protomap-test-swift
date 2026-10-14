import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardSlotsForRollup(_ items: [BedBoardSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveCensusRollupsFromSlot(_ items: [BedBoardSlot]) -> [CensusRollup] {
        var out: [CensusRollup] = []
        for item in items {
            let derived = newCensusRollup(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveCensusRollup(_ item: CensusRollup) -> String {
        return normalizeBedBoardTemplateCode(item.code)
    }
}
